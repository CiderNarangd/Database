#!/usr/bin/env bash
#

set -uo pipefail

# 로그인 셸 프로파일을 거치지 않는 실행(cron 등)에서도 percona-toolkit을 찾도록 보강
export PATH="/usr/local/percona-toolkit/bin:${PATH}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
STATE_DIR="${SCRIPT_DIR}/state"
REPORT_DIR="${SCRIPT_DIR}/reports"
LAST_RUN_FILE="${STATE_DIR}/last_run.ts"

for bin in jq curl pt-query-digest; do
  command -v "$bin" >/dev/null 2>&1 || { echo "[FATAL] '$bin' 명령이 필요합니다. 설치 후 다시 실행하세요." >&2; exit 1; }
done

[ -f "$ENV_FILE" ] || { echo "[FATAL] ${ENV_FILE} 파일이 없습니다. .env.example을 참고해 작성하세요." >&2; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

# DRY_RUN=1이면 Loki 조회/pt-query-digest까지만 수행하고 Claude API는 호출하지 않음(비용 없음)
DRY_RUN="${DRY_RUN:-0}"

if [ "$DRY_RUN" != "1" ]; then
  [ -n "${ANTHROPIC_API_KEY:-}" ] || { echo "[FATAL] ANTHROPIC_API_KEY가 설정되지 않았습니다." >&2; exit 1; }
fi

CLAUDE_MODEL="${CLAUDE_MODEL:-claude-opus-5}"
LOKI_URL="${LOKI_URL:-http://192.168.56.52:3100}"
TARGET_HOSTNAME="${TARGET_HOSTNAME:-mysql-84-source}"
TARGET_IP="${TARGET_IP:-192.168.56.201}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-oralce}"
TOP_N="${TOP_N:-5}"

mkdir -p "$STATE_DIR" "$REPORT_DIR"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

now_ns=$(date +%s%N)

# 최초 실행: 현재 시각만 기록하고 종료 (과거 백로그 분석 방지)
if [ ! -f "$LAST_RUN_FILE" ]; then
  printf '%s' "$now_ns" > "$LAST_RUN_FILE"
  echo "[INFO] 최초 실행입니다. 기준 시각(${now_ns})만 기록하고 종료합니다."
  exit 0
fi

start_ns=$(cat "$LAST_RUN_FILE")
end_ns="$now_ns"

# --- Loki에서 원본 슬로우 로그 라인 조회 ---
loki_response="${WORK_DIR}/loki_response.json"
query="{job=\"mysql_slowlog\", hostname=\"${TARGET_HOSTNAME}\"}"
http_status=$(curl -sS -o "$loki_response" -w '%{http_code}' \
  --get "${LOKI_URL}/loki/api/v1/query_range" \
  --data-urlencode "query=${query}" \
  --data-urlencode "start=${start_ns}" \
  --data-urlencode "end=${end_ns}" \
  --data-urlencode "direction=forward" \
  --data-urlencode "limit=5000")

if [ "$http_status" != "200" ]; then
  echo "[FATAL] Loki 조회 실패 (HTTP ${http_status}): $(cat "$loki_response")" >&2
  exit 1
fi

entry_count=$(jq '[.data.result[].values[]?] | length' "$loki_response")

if [ "$entry_count" -eq 0 ]; then
  echo "[INFO] 새로운 슬로우쿼리가 없습니다."
  printf '%s' "$end_ns" > "$LAST_RUN_FILE"
  exit 0
fi

# 타임스탬프 순으로 정렬한 뒤 원본 로그 본문만 이어붙여 하나의 텍스트로 병합
merged_log="${WORK_DIR}/merged_slow.log"
jq -r '[.data.result[].values[]?] | sort_by(.[0]) | .[][1]' "$loki_response" > "$merged_log"

echo "[INFO] 슬로우쿼리 ${entry_count}건 수집 완료. pt-query-digest 실행 중..."

# --- pt-query-digest로 정규화/집계 + EXPLAIN ---
dsn_file="${WORK_DIR}/pt-digest.cnf"
cat > "$dsn_file" <<EOF
[client]
host=${TARGET_IP}
port=3306
user=${DB_USER}
password=${DB_PASS}
EOF
chmod 600 "$dsn_file"

digest_report="${WORK_DIR}/digest_report.txt"
if ! pt-query-digest --type slowlog --limit "$TOP_N" --explain "F=${dsn_file}" - \
  < "$merged_log" > "$digest_report" 2>"${WORK_DIR}/pt-digest.err"; then
  echo "[WARN] pt-query-digest EXPLAIN 연동 실패, EXPLAIN 없이 재시도합니다: $(cat "${WORK_DIR}/pt-digest.err")" >&2
  pt-query-digest --type slowlog --limit "$TOP_N" - < "$merged_log" > "$digest_report"
fi

# --- Claude API 호출 ---
if [ "$DRY_RUN" = "1" ]; then
  echo "[INFO] DRY_RUN=1: Claude API 호출을 생략합니다 (비용 없음)."
  claude_text="(DRY_RUN 모드 - Claude API를 호출하지 않았습니다. 위 pt-query-digest 리포트만 확인하세요.)"
else
  echo "[INFO] Claude API(${CLAUDE_MODEL}) 호출 중..."

  system_prompt='당신은 MySQL 8.4 튜닝 전문 DBA입니다. 아래 pt-query-digest 리포트를 보고 한국어로 원인 분석과 구체적인 튜닝 방안(인덱스, 쿼리 재작성, 스키마 변경 등)을 제시하세요. 리포트에 있는 통계 수치(count, 실행시간 등)는 이미 정확히 계산되어 있으니 그대로 인용만 하고 새로 계산하거나 추정하지 마세요.'

  request_body="${WORK_DIR}/request.json"
  jq -n \
    --arg model "$CLAUDE_MODEL" \
    --arg system "$system_prompt" \
    --rawfile report "$digest_report" \
    '{model: $model, max_tokens: 8000, system: $system, messages: [{role: "user", content: $report}]}' \
    > "$request_body"

  api_response="${WORK_DIR}/api_response.json"
  http_status=$(curl -sS -o "$api_response" -w '%{http_code}' --max-time 180 \
    https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d @"$request_body")

  if [ "$http_status" != "200" ]; then
    echo "[FATAL] Claude API 호출 실패 (HTTP ${http_status}): $(cat "$api_response")" >&2
    exit 1
  fi

  stop_reason=$(jq -r '.stop_reason // "unknown"' "$api_response")
  if [ "$stop_reason" = "refusal" ]; then
    claude_text="(Claude API가 안전 정책상 이 요청을 거부했습니다. stop_reason=refusal)"
  else
    claude_text=$(jq -r '[.content[]? | select(.type=="text") | .text] | join("\n")' "$api_response")
  fi
fi

# --- 리포트 저장 ---
timestamp=$(date -u +%Y%m%d_%H%M%S)
report_file="${REPORT_DIR}/${TARGET_HOSTNAME}_${timestamp}.md"

{
  echo "# MySQL 슬로우쿼리 튜닝 리포트 - ${TARGET_HOSTNAME}"
  echo
  echo "- 생성 시각(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- 조회 구간: $(date -u -d "@$((start_ns / 1000000000))" +%Y-%m-%dT%H:%M:%SZ) ~ $(date -u -d "@$((end_ns / 1000000000))" +%Y-%m-%dT%H:%M:%SZ)"
  echo "- 신규 슬로우쿼리 로그 라인 수: ${entry_count}"
  echo
  echo "## pt-query-digest 리포트"
  echo
  echo '```'
  cat "$digest_report"
  echo '```'
  echo
  echo "## Claude 튜닝 제안"
  echo
  echo "$claude_text"
} > "$report_file"

printf '%s' "$end_ns" > "$LAST_RUN_FILE"

echo "[OK] 리포트 저장 완료: ${report_file}"
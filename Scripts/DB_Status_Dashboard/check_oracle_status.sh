#!/usr/bin/env bash
#
# Oracle 랩 상태 대시보드용 점검 스크립트 (크론 전용, 비대화형)
#
# lab_dashboard.oracle_hosts(enabled=1)를 순회하며 인스턴스 상태(pgrep ora_pmon)와
# Data Guard/RAC 상태(SQL*Plus, / as sysdba)를 점검해 lab_dashboard.checks에 적재한다.
# 신규 호스트가 생기면 oracle_hosts 테이블에 INSERT만 하면 자동으로 점검 대상에 포함된다.
#
# 크론 등록 예:
#   */5 * * * * /storage/scripts/check_oracle_status.sh >> /storage/scripts/logs/check_oracle_status.log 2>&1
#

set -uo pipefail

# cron은 기본 PATH(/sbin:/bin:/usr/sbin:/usr/bin)만 사용해 mysql 클라이언트(/usr/local/mysql/bin)를 못 찾는다.
export PATH="/usr/local/mysql/bin:${PATH}"

# ---- 로컬 lab_dashboard DB (Manager 호스트에 설치된 MySQL) ----
LOCAL_DB_HOST="localhost"
LOCAL_DB_USER="dashboard_writer"
LOCAL_DB_PASS="oralce"
LOCAL_DB_NAME="lab_dashboard"

# ---- 대상 Oracle 호스트 OS 계정 (ssh, sqlplus / as sysdba용) ----
SSH_USER="oracle"
SSH_PASS="oracle"
SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=5)

for bin in mysql sshpass; do
  command -v "$bin" >/dev/null 2>&1 || { echo "[FATAL] '$bin' 명령이 필요합니다. 설치 후 다시 실행하세요." >&2; exit 1; }
done

mysql_local() {
  MYSQL_PWD="$LOCAL_DB_PASS" mysql -h"$LOCAL_DB_HOST" -u"$LOCAL_DB_USER" -N -B "$@"
}

ssh_remote() {
  local ip=$1; shift
  SSHPASS="$SSH_PASS" sshpass -e ssh "${SSH_OPTS[@]}" "${SSH_USER}@${ip}" "$@" </dev/null 2>/dev/null
}

# oraenv로 환경 설정 후 SQL*Plus를 OS 인증("/ as sysdba")으로 실행
run_sql_remote() {
  local ip=$1 sid=$2 sql=$3 remote_script
  remote_script="export ORACLE_SID=${sid}
export ORAENV_ASK=NO
. oraenv >/dev/null 2>&1
sqlplus -s / as sysdba <<'SQLEOF'
set heading off feedback off pagesize 0 verify off trimspool on
${sql}
exit;
SQLEOF"
  ssh_remote "$ip" "$remote_script" | tr -d '\r' | sed '/^$/d'
}

# 인스턴스 프로세스 상태 (sid 없는 호스트는 ssh 접속 가능 여부만 확인)
check_instance_status() {
  local ip=$1 sid=$2 status
  if [ -z "$sid" ]; then
    status=$(ssh_remote "$ip" "echo active")
  else
    status=$(ssh_remote "$ip" "pgrep -f ora_pmon_${sid} >/dev/null 2>&1 && echo active || echo inactive")
  fi
  [ -z "$status" ] && status="unreachable"
  echo "$status"
}

# Data Guard Primary: DATABASE_ROLE=PRIMARY, OPEN_MODE=READ WRITE 확인
check_dg_primary_status() {
  local ip=$1 sid=$2 out role mode
  out=$(run_sql_remote "$ip" "$sid" "SELECT DATABASE_ROLE||'|'||OPEN_MODE FROM V\$DATABASE;" | tail -1)
  if [ -z "$out" ]; then
    echo "unreachable|"; return
  fi
  role=${out%%|*}; mode=${out#*|}
  if [ "$role" = "PRIMARY" ] && [[ "$mode" == READ\ WRITE* ]]; then
    echo "ok|"
  else
    echo "error|role=${role:-NA},mode=${mode:-NA}"
  fi
}

# Data Guard Standby: DATABASE_ROLE=PHYSICAL STANDBY + MRP(managed recovery) 적용 중 확인
check_dg_standby_status() {
  local ip=$1 sid=$2 role mrp
  role=$(run_sql_remote "$ip" "$sid" "SELECT DATABASE_ROLE FROM V\$DATABASE;" | tail -1)
  if [ -z "$role" ]; then
    echo "unreachable|"; return
  fi
  mrp=$(run_sql_remote "$ip" "$sid" "SELECT STATUS FROM V\$MANAGED_STANDBY WHERE PROCESS LIKE 'MRP%';" | tail -1)
  if [ "$role" = "PHYSICAL STANDBY" ] && [ "$mrp" = "APPLYING_LOG" ]; then
    echo "ok|"
  else
    echo "error|role=${role:-NA},mrp=${mrp:-NONE}"
  fi
}

# RAC 노드: 자신의 인스턴스 STATUS=OPEN 확인
check_rac_status() {
  local ip=$1 sid=$2 out
  out=$(run_sql_remote "$ip" "$sid" "SELECT STATUS FROM V\$INSTANCE;" | tail -1)
  if [ -z "$out" ]; then
    echo "unreachable|"
  elif [ "$out" = "OPEN" ]; then
    echo "ok|"
  else
    echo "error|${out}"
  fi
}

insert_check() {
  local hostname=$1 check_name=$2 status=$3 detail=$4
  mysql_local -D "$LOCAL_DB_NAME" -e \
    "INSERT INTO checks (hostname, check_name, status, detail) VALUES ('${hostname}','${check_name}','${status}','${detail}');"
}

run_status_check() {
  printf "%-24s %-10s %-12s %-30s\n" "HOSTNAME" "SID" "INSTANCE" "DG/RAC_STATUS"
  printf '%s\n' "--------------------------------------------------------------------------"

  local fail_count=0
  local hostname host_ip role sid inst_status role_raw role_status role_detail
  while IFS=$'\t' read -r hostname host_ip role sid; do
    [ -z "$hostname" ] && continue
    [ "$sid" = "NULL" ] && sid=""

    inst_status=$(check_instance_status "$host_ip" "$sid")
    insert_check "$hostname" "service" "$inst_status" ""

    case "$role" in
      dg_primary) role_raw=$(check_dg_primary_status "$host_ip" "$sid") ;;
      dg_standby) role_raw=$(check_dg_standby_status "$host_ip" "$sid") ;;
      rac_node)   role_raw=$(check_rac_status "$host_ip" "$sid") ;;
      *)          role_raw="n_a|" ;;
    esac
    role_status=${role_raw%%|*}
    role_detail=${role_raw#*|}
    insert_check "$hostname" "replication" "$role_status" "$role_detail"

    printf "%-24s %-10s %-12s %-30s\n" "$hostname" "${sid:-N/A}" "$inst_status" "$role_status"

    [ "$inst_status" != "active" ] && fail_count=$((fail_count + 1))
    case "$role_status" in
      error|unreachable) fail_count=$((fail_count + 1)) ;;
    esac
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e "SELECT hostname, host_ip, role, oracle_sid FROM oracle_hosts WHERE enabled = 1;")

  printf '%s\n' "--------------------------------------------------------------------------"
  if [ "$fail_count" -eq 0 ]; then
    echo "[OK] 모든 호스트 정상"
    return 0
  else
    echo "[WARN] 이상 감지 ${fail_count}건 (lab_dashboard.checks 참고)"
    return 1
  fi
}

run_status_check
exit $?

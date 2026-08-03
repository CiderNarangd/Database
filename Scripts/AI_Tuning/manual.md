
# MySQL 슬로우쿼리 AI 튜닝 파이프라인 — 사용 설명서

`mysql 서버`의 슬로우쿼리를 Loki에서 가져와 pt-query-digest로 집계하고, Claude API로 한국어 튜닝 제안을 받아 마크다운 리포트로 저장합니다. (설계/흐름 상세는 `pipeline.md` 참고)

## 1. 사전 준비

- 사용할 호스트에 `jq`, `curl`, `pt-query-digest`(Percona Toolkit) 설치 필요
- `.env` 파일 작성 (최초 1회)
  ```bash
  cp .env.example .env
  vi .env   # ANTHROPIC_API_KEY, 접속 정보 등 채우기
  ```

## 2. 실행

```bash
bash ai_tuning.sh
```

| 상황 | 동작 |
|---|---|
| `state/last_run.ts` 없음(최초 실행) | 현재 시각만 기록하고 종료 (API 호출 없음) |
| 신규 슬로우쿼리 0건 | "새로운 슬로우쿼리가 없습니다" 출력 후 종료 (API 호출 없음) |
| 신규 슬로우쿼리 있음 | Loki 조회 → pt-query-digest → Claude API → `reports/호스트명_타임스탬프.md` 생성 |

### 비용 없이 테스트만 하고 싶을 때
```bash
DRY_RUN=1 bash ai_tuning.sh
```
Claude API 호출을 생략하고 Loki 조회 + pt-query-digest 결과까지만 확인합니다.

## 3. 결과 확인

```bash
ls reports/
cat reports/mysql-84-source_최신타임스탬프.md
```

리포트는 pt-query-digest 통계(원본, 수치 그대로) + Claude 튜닝 제안(원인 분석, 인덱스/쿼리 재작성 제안)으로 구성됩니다.

## 4. 동작 원리 요약

- 같은 쿼리 패턴(리터럴 값만 다른 경우)은 pt-query-digest가 자동으로 하나로 묶어서 집계합니다. 발생 횟수가 아무리 많아도 리포트/Claude 호출 비용은 **고유 패턴 수(`TOP_N`, 기본 5개)**에만 비례합니다.
- 한 실행 구간에 슬로우쿼리 원본 로그가 5000건을 넘으면 Loki 조회 단계(`limit=5000`)에서 잘릴 수 있습니다. 평소보다 훨씬 많이 발생하는 상황이 잦다면 스크립트의 `limit` 값을 늘리는 걸 검토하세요.

## 5. 파일 위치 요약 (`/tuning`)

```
ai_tuning.sh               # 메인 실행 스크립트
.env / .env.example        # 설정 값 (.env는 커밋 금지)
pipeline.md                # 설계/아키텍처 상세 문서
설명서.md                   # 이 파일 (사용 설명서)
state/last_run.ts          # 마지막 조회 시각 (자동 관리)
reports/*.md               # 실행마다 생성되는 튜닝 리포트
```
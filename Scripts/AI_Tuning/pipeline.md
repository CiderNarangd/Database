# MySQL 슬로우쿼리 AI 튜닝 파이프라인 

`mysql 서버`의 슬로우쿼리를 Loki에서 가져와 pt-query-digest로 집계하고, Claude API로 튜닝 제안을 받아 마크다운 리포트로 저장한다. 
```
AI - Claude opus 5
target host - mysql-84-source
```
## 아키텍처

```
mysql-84-source (슬로우 로그)
        │ Grafana Alloy가 실시간 수집
        ▼
   Loki (192.168.56.52:3100)
        │ ai_tuning.sh가 LogQL로 신규 구간만 조회
        ▼
pt-query-digest --explain
   (쿼리 정규화·집계 + EXPLAIN 자동 실행)
        │
        ▼
   Claude API (claude-opus-5)
        │
        ▼
  tuning/reports/*.md
```

## 왜 이렇게 구성했나 

- **SSH 대신 Loki**: 기존의 이미 구축되어 있는 로그 수집(Loki) 파이프라인 활용 ( 향후 oracle, pgsql 등 확장 예정 )
- **자체 파서 대신 pt-query-digest**: 쿼리 정규화(fingerprint)와 EXPLAIN 연동을 검증된 도구에 맡겨 튜닝 품질을 확보. 

## 실행 흐름

1. `.env` 로드, `state/last_run.ts` 확인
   - 없으면(최초 실행) 현재 시각만 기록하고 종료 — 과거 백로그 분석 방지
2. Loki에서 `last_run.ts` ~ 현재까지 신규 슬로우 로그 조회
3. 0건이면 종료(비용 없음). 있으면 시간순 정렬 후 텍스트로 병합
4. `pt-query-digest --type slowlog --limit N --explain ...`로 정규화·집계 + EXPLAIN
5. 그 결과(리포트)를 그대로 Claude API에 전달해 튜닝 제안 요청
   - 수치(count, 실행시간 등)는 이미 결정적으로 계산돼 있으므로 AI에게 재계산시키지 않음
6. pt-query-digest 결과 + Claude 응답을 합쳐 `reports/호스트명_타임스탬프.md` 저장
7. `state/last_run.ts` 갱신

## 핵심 설계 포인트

- **같은 쿼리 패턴은 자동으로 합쳐짐**: 리터럴 값만 다른 쿼리(`col1='123'` vs `col1='456'`)는 pt-query-digest가 하나의 fingerprint로 묶음. 비용은 발생 횟수가 아니라 고유 패턴 수(`TOP_N`, 기본 5개)에 비례.
- **비용 안전장치 2가지**: 최초 실행 시 API 호출 생략 / 신규 쿼리 0건이면 API 호출 생략.
- **실패해도 데이터 유실 없음**: API 호출 실패 시 `state/last_run.ts`를 갱신하지 않아 다음 실행 때 그대로 재처리.

## 설정 (`.env`)

| 변수 | 기본값 |
|---|---|
| `ANTHROPIC_API_KEY` | (필수) |
| `CLAUDE_MODEL` | `claude-opus-5` |
| `LOKI_URL` | `http://192.168.56.52:3100` |
| `TARGET_HOSTNAME` / `TARGET_IP` | `mysql-84-source` / `192.168.56.201` |
| `DB_USER` / `DB_PASS` | EXPLAIN용 DB 계정 |
| `TOP_N` | `5` |

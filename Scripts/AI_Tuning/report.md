# MySQL 슬로우쿼리 튜닝 리포트 - mysql-84-source

- 생성 시각(UTC): 2026-08-03T13:36:12Z
- 조회 구간: 2026-08-03T13:22:10Z ~ 2026-08-03T13:34:22Z
- 신규 슬로우쿼리 로그 라인 수: 2

## pt-query-digest 리포트

```
Reading from STDIN ...

# 140ms user time, 20ms system time, 43.46M rss, 268.36M vsz
# Current date: Mon Aug  3 22:34:22 2026
# Hostname: manager
# Files: STDIN
# Overall: 2 total, 2 unique, 0.14 QPS, 0.60x concurrency ________________
# Time range: 2026-08-03T13:34:02 to 2026-08-03T13:34:16
# Attribute          total     min     max     avg     95%  stddev  median
# ============     ======= ======= ======= ======= ======= ======= =======
# Exec time             8s      3s      5s      4s      5s      2s      4s
# Lock time            3us       0     3us     1us     3us     2us     1us
# Rows sent           1001       1    1000  500.50    1000  706.40  500.50
# Rows examine     195.31k       1 195.31k  97.66k 195.31k 138.11k  97.66k
# Bytes sent        18.13k      56  18.07k   9.06k  18.07k  12.74k   9.06k
# Query size           129      15     114   64.50     114   70.00   64.50
# Bytes receiv         143      22     121   71.50     121   70.00   71.50
# Created tmp            1       0       1    0.50       1    0.71    0.50
# Created tmp            1       0       1    0.50       1    0.71    0.50
# Errno                  0       0       0       0       0       0       0
# Read first             3       0       3    1.50       3    2.12    1.50
# Read key           9.63M       0   9.63M   4.82M   9.63M   6.81M   4.82M
# Read last              0       0       0       0       0       0       0
# Read next              0       0       0       0       0       0       0
# Read prev              0       0       0       0       0       0       0
# Read rnd               0       0       0       0       0       0       0
# Read rnd nex     197.27k       0 197.27k  98.63k 197.27k 139.49k  98.63k
# Sort merge p           0       0       0       0       0       0       0
# Sort range c           0       0       0       0       0       0       0
# Sort rows              0       0       0       0       0       0       0
# Sort scan co           0       0       0       0       0       0       0

# Profile
# Rank Query ID                            Response time Calls R/Call V/M 
# ==== =================================== ============= ===== ====== ====
#    1 0x4D839F02910E9B3B6531D8A6F515A530   5.3304 63.9%     1 5.3304  0.00 SELECT slow_dummy
#    2 0x59A74D08D407B5EDF9A57DD5A41825CA   3.0116 36.1%     1 3.0116  0.00 SELECT

# Query 1: 0 QPS, 0x concurrency, ID 0x4D839F02910E9B3B6531D8A6F515A530 at byte 0
# This item is included in the report because it matches --limit.
# Scores: V/M = 0.00
# Time range: all events occurred at 2026-08-03T13:34:02
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count         50       1
# Exec time     63      5s      5s      5s      5s      5s       0      5s
# Lock time    100     3us     3us     3us     3us     3us       0     3us
# Rows sent     99    1000    1000    1000    1000    1000       0    1000
# Rows examine  99 195.31k 195.31k 195.31k 195.31k 195.31k       0 195.31k
# Bytes sent    99  18.07k  18.07k  18.07k  18.07k  18.07k       0  18.07k
# Query size    88     114     114     114     114     114       0     114
# Bytes receiv  84     121     121     121     121     121       0     121
# Created tmp  100       1       1       1       1       1       0       1
# Created tmp  100       1       1       1       1       1       0       1
# Errno          0       0       0       0       0       0       0       0
# Read first   100       3       3       3       3       3       0       3
# Read key     100   9.63M   9.63M   9.63M   9.63M   9.63M       0   9.63M
# Read last      0       0       0       0       0       0       0       0
# Read next      0       0       0       0       0       0       0       0
# Read prev      0       0       0       0       0       0       0       0
# Read rnd       0       0       0       0       0       0       0       0
# Read rnd nex 100 197.27k 197.27k 197.27k 197.27k 197.27k       0 197.27k
# Sort merge p   0       0       0       0       0       0       0       0
# Sort range c   0       0       0       0       0       0       0       0
# Sort rows      0       0       0       0       0       0       0       0
# Sort scan co   0       0       0       0       0       0       0       0
# String:
# End          2026-08-03T13:34:02.570857Z
# Hosts        localhost
# Start        2026-08-03T13:33:57.240478Z
# Users        root
# Query_time distribution
#   1us
#  10us
# 100us
#   1ms
#  10ms
# 100ms
#    1s  ################################################################
#  10s+
# Tables
#    SHOW TABLE STATUS LIKE 'slow_dummy'\G
#    SHOW CREATE TABLE `slow_dummy`\G
# EXPLAIN /*!50100 PARTITIONS*/
SELECT a.user_name, COUNT(*) FROM slow_dummy a JOIN slow_dummy b ON a.user_name = b.user_name GROUP BY a.user_name\G
# EXPLAIN failed: DBD::mysql::st execute failed: No database selected [for Statement "EXPLAIN SELECT a.user_name, COUNT(*) FROM slow_dummy a JOIN slow_dummy b ON a.user_name = b.user_name GROUP BY a.user_name"] at /usr/local/percona-toolkit/bin/pt-query-digest line 7799.

# Query 2: 0 QPS, 0x concurrency, ID 0x59A74D08D407B5EDF9A57DD5A41825CA at byte 678
# This item is included in the report because it matches --limit.
# Scores: V/M = 0.00
# Time range: all events occurred at 2026-08-03T13:34:16
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count         50       1
# Exec time     36      3s      3s      3s      3s      3s       0      3s
# Lock time      0       0       0       0       0       0       0       0
# Rows sent      0       1       1       1       1       1       0       1
# Rows examine   0       1       1       1       1       1       0       1
# Bytes sent     0      56      56      56      56      56       0      56
# Query size    11      15      15      15      15      15       0      15
# Bytes receiv  15      22      22      22      22      22       0      22
# Created tmp    0       0       0       0       0       0       0       0
# Created tmp    0       0       0       0       0       0       0       0
# Errno          0       0       0       0       0       0       0       0
# Read first     0       0       0       0       0       0       0       0
# Read key       0       0       0       0       0       0       0       0
# Read last      0       0       0       0       0       0       0       0
# Read next      0       0       0       0       0       0       0       0
# Read prev      0       0       0       0       0       0       0       0
# Read rnd       0       0       0       0       0       0       0       0
# Read rnd nex   0       0       0       0       0       0       0       0
# Sort merge p   0       0       0       0       0       0       0       0
# Sort range c   0       0       0       0       0       0       0       0
# Sort rows      0       0       0       0       0       0       0       0
# Sort scan co   0       0       0       0       0       0       0       0
# String:
# End          2026-08-03T13:34:16.802311Z
# Hosts        localhost
# Start        2026-08-03T13:34:13.790705Z
# Users        root
# Query_time distribution
#   1us
#  10us
# 100us
#   1ms
#  10ms
# 100ms
#    1s  ################################################################
#  10s+
# EXPLAIN 
select sleep(3)\G
# *************************** 1. row ***************************
#            id: 1
#   select_type: SIMPLE
#         table: NULL
#    partitions: NULL
#          type: NULL
# possible_keys: NULL
#           key: NULL
#       key_len: NULL
#           ref: NULL
#          rows: NULL
```

## Claude 튜닝 제안

# pt-query-digest 분석 리포트 (MySQL 8.4)

## 0. 샘플 전체 개요 — 먼저 짚어둘 점

| 항목 | 값 |
|---|---|
| Overall | 2 total, 2 unique, 0.14 QPS, 0.60x concurrency |
| Time range | 2026-08-03T13:34:02 ~ 13:34:16 (약 14초 구간) |
| Exec time | total 8s / min 3s / max 5s / avg 4s |
| Rows sent | total 1001 (max 1000) |
| Rows examine | total 195.31k (max 195.31k) |
| Created tmp (tables / disk tables) | 각각 total 1 |
| Read key | total 9.63M |
| Read rnd next | total 197.27k |

즉 **14초 구간에 슬로우 쿼리 2건만 수집된, 사실상 테스트/재현용 샘플**입니다. 워크로드 대표성이 없으므로 "튜닝 우선순위 산정"용으로는 부족하고, 지금 리포트는 **두 개의 명확한 안티패턴을 진단하는 용도**로만 사용해야 합니다. (수집 개선 방안은 5장)

---

## 1. Query 1 — `SELECT ... FROM slow_dummy a JOIN slow_dummy b ON a.user_name = b.user_name GROUP BY a.user_name`

**리포트 수치 (인용)**
- Response time 5.3304s (63.9%), Calls 1, R/Call 5.3304
- Rows sent 1000 / Rows examine 195.31k
- Created tmp tables 1, **Created tmp disk tables 1**
- Read first 3, **Read key 9.63M**, Read rnd next 197.27k
- Read next / prev / rnd 모두 0, Sort rows·Sort scan 모두 0

### 1-1. 원인 분석

**(1) `user_name`에 사용 가능한 인덱스가 없다 (핵심 원인)**
- `Read next = 0`, `Read prev = 0`, `Read rnd = 0`인데 `Read rnd next = 197.27k`입니다. `Read rnd next`는 **테이블(또는 내부 임시테이블) 순차 스캔** 시 증가하는 카운터이므로, 조인·집계 처리가 **인덱스 순차 접근이 아니라 풀 스캔 기반**으로 수행되었음을 보여줍니다.
- `Read first = 3`은 스캔 시작이 3회 발생했다는 의미로, `a` 스캔 + `b` 스캔 + 임시테이블 스캔 형태의 처리 흐름과 부합합니다.
- 결과적으로 **Rows sent 1000 vs Rows examine 195.31k** — 반환 행 수에 비해 읽은 행 수가 압도적으로 큽니다. 전형적인 "인덱스 없는 조인" 시그니처입니다.

**(2) 조인 키 매칭/집계 조회 횟수가 극단적으로 많다**
- `Read key = 9.63M`은 키 기반 조회(내부 임시테이블의 그룹 키 lookup 및 조인 키 매칭 포함)가 수백만 회 수행되었다는 뜻입니다. 조인 결과 행마다 그룹 키를 찾아 카운터를 갱신하는 구조에서 발생하며, **조인 결과 건수 자체가 폭발적으로 불어났음**을 시사합니다.
- 이는 뒤의 (4) "self-join 카티전 증폭"과 직접 연결됩니다.

**(3) GROUP BY용 내부 임시테이블이 디스크로 떨어졌다**
- `Created tmp tables 1`과 `Created tmp disk tables 1`이 **동시에 1** → 만들어진 임시테이블이 메모리에 머물지 못하고 **디스크 임시테이블로 전환**되었습니다.
- `Sort rows = 0`, `Sort scan = 0`이므로 filesort는 없고, **임시테이블 기반 집계(aggregation)** 가 비용의 중심입니다. 즉 정렬이 아니라 **임시테이블 I/O + 대량 키 lookup**이 5.3304초의 주 원인입니다.

**(4) 쿼리 자체가 논리적으로 잘못됐을 가능성이 매우 높다 (가장 중요)**
```sql
SELECT a.user_name, COUNT(*)
FROM slow_dummy a JOIN slow_dummy b ON a.user_name = b.user_name
GROUP BY a.user_name;
```
동일 테이블을 동일 키로 self-join 하면, 같은 `user_name` 그룹 안에서 **행들이 서로 전부 매칭되어 그룹별로 카티전 곱**이 발생합니다. 따라서
- 이 `COUNT(*)`는 "사용자별 건수"가 아니라 **건수의 제곱**에 해당하는 값이며,
- 중간 결과가 제곱으로 불어나므로 `Read key 9.63M` / `Rows examine 195.31k` / 디스크 임시테이블이 모두 이 증폭의 결과입니다.

**의도가 "user_name별 건수"라면 self-join은 불필요한 낭비이고, 인덱스를 붙이는 것보다 쿼리를 지우는 것이 훨씬 큰 효과를 냅니다.**

### 1-2. 튜닝 방안

#### ① 쿼리 재작성 (1순위, 비용 0, 효과 최대)

의도가 사용자별 건수인 경우 — **조인 제거**:
```sql
SELECT user_name, COUNT(*) AS cnt
FROM slow_dummy
GROUP BY user_name;
```

만약 정말로 "같은 이름끼리의 조합 수"가 필요하다면, 조인 없이 집계 후 계산하도록 바꿉니다(조인 결과 폭발을 원천 차단):
```sql
SELECT user_name, COUNT(*) * COUNT(*) AS pair_cnt      -- 자기쌍 포함
FROM slow_dummy
GROUP BY user_name;
-- 자기쌍 제외가 필요하면 COUNT(*) * (COUNT(*) - 1)
```

`b` 테이블이 "존재 여부 필터" 용도였다면 조인이 아니라 세미조인으로:
```sql
SELECT a.user_name, COUNT(*)
FROM slow_dummy a
WHERE EXISTS (SELECT 1 FROM slow_dummy b WHERE b.user_name = a.user_name /* + 추가 조건 */)
GROUP BY a.user_name;
```

또한 `Rows sent 1000`이므로 화면/API 용도라면 **정렬 기준을 명시한 LIMIT 페이징**을 적용해 전송량과 임시테이블 크기를 줄입니다.
```sql
SELECT user_name, COUNT(*) AS cnt
FROM slow_dummy
GROUP BY user_name
ORDER BY user_name
LIMIT 100 OFFSET 0;
```

#### ② 인덱스 추가 (2순위)

```sql
ALTER TABLE slow_dummy ADD INDEX ix_slow_dummy_user_name (user_name);
```
기대 효과
- 조인이 남아 있을 경우: 풀 스캔 대신 `ref` 접근 또는 인덱스 기반 hash join으로 전환되어 `Rows examine`이 감소.
- `GROUP BY user_name`이 **인덱스 순서를 그대로 사용**할 수 있어 집계용 임시테이블(그리고 디스크 전환)을 제거할 수 있습니다. EXPLAIN에서 `Using index for group-by` 또는 최소한 `Using temporary`가 사라지는지 확인하십시오.

집계에 다른 컬럼도 함께 쓰인다면 **커버링 인덱스**로 확장:
```sql
-- 예: WHERE reg_date >= ? AND user_name별 집계라면
ALTER TABLE slow_dummy ADD INDEX ix_dummy_date_user (reg_date, user_name);
-- 예: user_name별 집계 + 특정 컬럼 SUM 이라면
ALTER TABLE slow_dummy ADD INDEX ix_dummy_user_amt (user_name, amount);
```
(선행 컬럼 선정은 실제 WHERE 절 유무에 따라 결정해야 하므로, 현재 리포트의 쿼리 원문만으로는 `user_name` 단일 인덱스가 기본입니다.)

#### ③ 스키마 점검/변경

리포트에 `SHOW CREATE TABLE slow_dummy` 결과가 없어 반드시 확인해야 하는 항목:

1. **`user_name` 자료형과 길이**
   - `VARCHAR(255) utf8mb4`처럼 과대한 정의면 인덱스 키가 커져 조인·임시테이블 비용이 커집니다. 실제 최대 길이에 맞춰 축소(예: `VARCHAR(50)`)하거나, 인덱스에 접두어 길이를 지정합니다.
   ```sql
   ALTER TABLE slow_dummy MODIFY user_name VARCHAR(50) NOT NULL;
   -- 또는
   ALTER TABLE slow_dummy ADD INDEX ix_user_name (user_name(20));
   ```
2. **양쪽 조인 컬럼의 타입·문자셋·collation 동일성**
   - self-join이므로 동일 컬럼이지만, 향후 다른 테이블과 조인할 때 charset/collation 불일치는 인덱스 무효화(암묵적 형변환)의 주원인입니다. 전 테이블 `utf8mb4_0900_ai_ci` 등으로 통일.
3. **NULL 허용 여부** — `user_name`이 NULL 가능이면 조인/그룹 처리에 불필요한 분기가 생깁니다. 가능하면 `NOT NULL`.
4. **PRIMARY KEY 존재 여부** — PK가 없으면 InnoDB가 숨은 6바이트 row_id를 쓰고 세컨더리 인덱스 효율도 떨어집니다. 반드시 명시적 PK 부여.
5. **정규화 관점** — `user_name`(문자열)이 반복 저장되고 있다면 `user_id`(INT/BIGINT) 기준으로 조인·집계하도록 변경하는 것이 근본 해결입니다. 문자열 키 비교가 사라져 `Read key`성 비용이 크게 줄어듭니다.
6. **집계 상시 조회라면 사전 집계 도입** — 사용자별 건수를 자주 조회한다면 요약 테이블(배치/트리거 갱신)이나 카운터 컬럼 유지로 매 조회 집계를 없애는 방안을 검토.

#### ④ 서버 파라미터 (보조 수단, 인덱스/쿼리 수정이 우선)

`Created tmp disk tables 1`에 대한 대응:
```sql
SHOW VARIABLES LIKE 'tmp_table_size';
SHOW VARIABLES LIKE 'max_heap_table_size';
SHOW VARIABLES LIKE 'internal_tmp_mem_storage_engine';   -- 8.4 기본 TempTable
SHOW VARIABLES LIKE 'temptable_max_ram';
SHOW VARIABLES LIKE 'temptable_max_mmap';
SHOW VARIABLES LIKE 'join_buffer_size';                   -- hash join 시 사용
```
- 내부 임시테이블 엔진이 TempTable인 경우 메모리 한계는 `temptable_max_ram`/`temptable_max_mmap`이 지배합니다. 값이 지나치게 낮게 조정돼 있지 않은지 확인하고, 필요 시 **세션 단위**로만 상향해 배치성 쿼리를 처리하십시오(전역 상향은 동시 세션 수만큼 메모리를 곱해서 소비하므로 위험).
- 인덱스가 없는 조인은 8.0.20 이후 hash join으로 처리되므로, 인덱스 도입 전 임시 완화책으로 해당 세션의 `join_buffer_size`를 올리면 개선될 수 있습니다. 단 이 역시 **세션 단위**로만 적용하는 것을 권장합니다.
- 어디까지나 증상 완화이며, ①·②를 적용하면 임시테이블 자체가 사라지는 것이 정상 목표입니다.

---

## 2. Query 2 — `select sleep(3)`

**리포트 수치 (인용)**
- Response time 3.0116s (36.1%), Calls 1
- Rows sent 1 / Rows examine 1, Bytes sent 56, Query size 15
- Created tmp 0, Read key 0, Read rnd next 0, Sort 관련 전부 0
- EXPLAIN: table NULL, type NULL, key NULL, rows NULL

### 원인 분석
`SLEEP(3)`은 **의도적으로 3초를 대기하는 함수**이며, EXPLAIN 결과가 전부 NULL이고 `Rows examine 1`인 것에서 알 수 있듯이 **테이블 접근·인덱스·임시테이블과 무관**합니다. 즉 **DB 튜닝 대상이 아닌 쿼리**입니다. 전체 응답시간의 36.1%를 차지하지만 이는 데이터베이스 성능 문제가 아니라 대기 그 자체입니다.

### 조치
1. **슬로우 로그 테스트 목적이라면**: 정상. 다만 이 항목이 프로파일 상위를 차지해 실제 문제 쿼리를 가리므로, 다음처럼 리포팅에서 제외하십시오.
   ```bash
   pt-query-digest --filter '$event->{fingerprint} !~ m/sleep/i' slow.log
   ```
2. **애플리케이션/헬스체크/스크립트에서 실제로 호출되고 있다면**: 즉시 제거해야 합니다. `SLEEP()`은 커넥션과 스레드를 점유해 커넥션 풀 고갈, `max_connections` 압박, 락 보유 시간 증가를 유발합니다. 지연이 필요하면 애플리케이션 레이어에서 처리하십시오.
3. **점검 포인트**: `long_query_time` 값이 3초 미만으로 설정되어 있어 이 쿼리가 잡힌 것으로 보입니다. 운영 기준에 맞는지 확인하십시오.
   ```sql
   SHOW VARIABLES LIKE 'long_query_time';
   SHOW VARIABLES LIKE 'slow_query_log%';
   SHOW VARIABLES LIKE 'log_queries_not_using_indexes';
   ```
   `log_queries_not_using_indexes`를 켤 경우 Query 1 유형(인덱스 미사용)을 조기에 잡아낼 수 있지만, 로그량 폭증에 대비해 `log_throttle_queries_not_using_indexes`를 함께 설정하십시오.

---

## 3. 우선순위 요약

| 순위 | 대상 | 조치 | 근거 수치 |
|---|---|---|---|
| 1 | Query 1 | self-join 제거(쿼리 재작성) | Read key 9.63M, Rows examine 195.31k vs Rows sent 1000 |
| 2 | Query 1 | `slow_dummy(user_name)` 인덱스 추가 (필요 시 커버링) | Read rnd next 197.27k, Read next/prev/rnd = 0 |
| 3 | Query 1 | 디스크 임시테이블 제거(인덱스 우선, 부족 시 세션 파라미터) | Created tmp tables 1 + Created tmp disk tables 1 |
| 4 | Query 1 | `user_name` 타입/길이 축소, PK·NOT NULL, user_id 정규화 | 스키마 미확인 → 확인 필요 |
| 5 | Query 2 | `SLEEP(3)` 제거 또는 리포트 필터링 | EXPLAIN 전부 NULL, Rows examine 1 |
| 6 | 수집 체계 | EXPLAIN 실패 해소, 수집 기간 확대 | 아래 5장 |

---

## 4. 검증 절차

적용 전/후로 동일하게 측정합니다.

```sql
-- 1) 실행계획: Using temporary / Using filesort / hash join / type 컬럼 확인
EXPLAIN FORMAT=JSON
SELECT user_name, COUNT(*) FROM slow_dummy GROUP BY user_name;

-- 2) 실측 (actual rows/time, 임시테이블 여부까지 확인)
EXPLAIN ANALYZE
SELECT user_name, COUNT(*) FROM slow_dummy GROUP BY user_name;

-- 3) 핸들러 카운터 비교 (Read key / Read rnd next 감소, Rows examined 감소 확인)
FLUSH STATUS;
SELECT user_name, COUNT(*) FROM slow_dummy GROUP BY user_name;
SHOW SESSION STATUS LIKE 'Handler_read%';
SHOW SESSION STATUS LIKE 'Created_tmp%';   -- disk tables 가 0 인지 확인
SHOW SESSION STATUS LIKE 'Sort%';
```
성공 기준
- `Created_tmp_disk_tables` = 0
- `Handler_read_rnd_next`, `Handler_read_key`가 리포트 값 대비 대폭 감소
- `Rows examine`이 `Rows sent`에 근접
- EXPLAIN에서 `Using temporary` 소멸(또는 `Using index for group-
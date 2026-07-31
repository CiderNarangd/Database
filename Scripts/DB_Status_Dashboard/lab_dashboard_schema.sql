-- lab_dashboard: MySQL 랩 상태 대시보드 전용 스키마.
-- Manager 호스트(192.168.56.51)에 설치된 MySQL 8.4에 생성한다.
-- 기존 db_list 스키마와는 완전히 독립적이며, check_mysql_status.sh / webapp이 참조한다.

CREATE DATABASE IF NOT EXISTS lab_dashboard DEFAULT CHARACTER SET utf8mb4;

USE lab_dashboard;

-- 점검 대상 호스트 목록. db_type/check_name을 값으로 두어 향후(Oracle, 다른 점검 종류)
-- 테이블 구조 변경 없이 행 추가만으로 확장 가능하도록 설계.
CREATE TABLE IF NOT EXISTS hosts (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  hostname      VARCHAR(64) NOT NULL UNIQUE,
  host_ip       VARCHAR(45) NOT NULL,
  db_type       VARCHAR(20) NOT NULL DEFAULT 'mysql',
  cluster_type  VARCHAR(20) NOT NULL,
  role          VARCHAR(20) NOT NULL,
  service_name  VARCHAR(30) NOT NULL DEFAULT 'mysqld',
  enabled       TINYINT(1) NOT NULL DEFAULT 1,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Oracle 점검 대상 호스트 목록. hosts(MySQL 계열)와는 별도 테이블로 분리.
CREATE TABLE IF NOT EXISTS oracle_hosts (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  hostname        VARCHAR(64) NOT NULL UNIQUE,
  host_ip         VARCHAR(45) NOT NULL,
  cluster_type    VARCHAR(20) NOT NULL,   -- standalone / dataguard / rac
  role            VARCHAR(20) NOT NULL,   -- si / dg_primary / dg_standby / rac_node / rman
  oracle_sid      VARCHAR(30) DEFAULT NULL,
  db_unique_name  VARCHAR(30) DEFAULT NULL,
  enabled         TINYINT(1) NOT NULL DEFAULT 1,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 점검 결과 이력. hosts/oracle_hosts 공용 — hostname + check_name 단위로 행이 쌓이므로
-- 새 점검 종류나 새 호스트군이 생겨도 스키마 변경이 필요 없다.
CREATE TABLE IF NOT EXISTS checks (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  hostname    VARCHAR(64) NOT NULL,
  check_name  VARCHAR(40) NOT NULL,
  status      VARCHAR(20) NOT NULL,
  detail      VARCHAR(255) NOT NULL DEFAULT '',
  checked_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_host_check_time (hostname, check_name, checked_at)
);

-- 초기 호스트 목록 (인프라 표 기준, MySQL 계열만)
INSERT INTO hosts (hostname, host_ip, db_type, cluster_type, role, service_name) VALUES
  ('mysql-84-source',   '192.168.56.201', 'mysql', 'replication', 'source',    'mysqld'),
  ('mysql-84-replica',  '192.168.56.202', 'mysql', 'replication', 'replica',   'mysqld'),
  ('mysql-ibc-router',  '192.168.56.210', 'mysql', 'ibc',         'router',    'mysqlrouter'),
  ('mysql-ibc-primary', '192.168.56.211', 'mysql', 'ibc',         'primary',   'mysqld'),
  ('mysql-ibc-sec01',   '192.168.56.212', 'mysql', 'ibc',         'secondary', 'mysqld'),
  ('mysql-ibc-sec02',   '192.168.56.213', 'mysql', 'ibc',         'secondary', 'mysqld'),
  ('mysql-84-backup',   '192.168.56.222', 'mysql', 'standalone',  'backup',    'mysqld')
ON DUPLICATE KEY UPDATE host_ip = VALUES(host_ip);

-- 초기 호스트 목록 (인프라 표 기준, Oracle 계열)
INSERT INTO oracle_hosts (hostname, host_ip, cluster_type, role, oracle_sid, db_unique_name) VALUES
  ('orcl-19c-si',          '192.168.56.101', 'standalone', 'si',         'orcl',    NULL),
  ('orcl-19c-dg-primary',  '192.168.56.102', 'dataguard',  'dg_primary', 'orcl',    NULL),
  ('orcl-19c-dg-standby',  '192.168.56.103', 'dataguard',  'dg_standby', 'orcl',    NULL),
  ('orcl-19c-rac01',       '192.168.56.11',  'rac',        'rac_node',   'orcl191', 'orcl'),
  ('orcl-19c-rac02',       '192.168.56.12',  'rac',        'rac_node',   'orcl192', 'orcl'),
  ('orcl-19c-rac03',       '192.168.56.13',  'rac',        'rac_node',   'orcl193', 'orcl'),
  ('orcl-19c-rman',        '192.168.56.199', 'standalone', 'rman',       NULL,      NULL)
ON DUPLICATE KEY UPDATE host_ip = VALUES(host_ip);

-- 대시보드 전용 DB 계정 분리 (root 재사용 금지)
CREATE USER IF NOT EXISTS 'dashboard_writer'@'localhost' IDENTIFIED BY 'oralce';
GRANT SELECT, INSERT ON lab_dashboard.* TO 'dashboard_writer'@'localhost';

CREATE USER IF NOT EXISTS 'dashboard_ro'@'localhost' IDENTIFIED BY 'oralce';
GRANT SELECT ON lab_dashboard.* TO 'dashboard_ro'@'localhost';

FLUSH PRIVILEGES;

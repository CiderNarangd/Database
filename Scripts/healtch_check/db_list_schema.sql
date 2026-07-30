-- db_list: Manager 호스트(192.168.56.51)에 설치된 MySQL 8.4에 생성하는
-- 헬스체크 대상 관리용 스키마. health_check_mysql.sh 가 참조한다.

CREATE DATABASE IF NOT EXISTS db_list DEFAULT CHARACTER SET utf8mb4;

USE db_list;

-- 헬스체크 대상 호스트 목록
CREATE TABLE IF NOT EXISTS host_list (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  hostname      VARCHAR(64) NOT NULL UNIQUE,
  host_ip       VARCHAR(45) NOT NULL,
  cluster_type  ENUM('replication','ibc','standalone') NOT NULL,
  role          ENUM('source','replica','router','primary','secondary','backup') NOT NULL,
  service_name  VARCHAR(30) NOT NULL DEFAULT 'mysqld',
  enabled       TINYINT(1) NOT NULL DEFAULT 1,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 헬스체크 실행 이력
CREATE TABLE IF NOT EXISTS health_check_log (
  id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
  hostname            VARCHAR(64) NOT NULL,
  check_time          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  service_name        VARCHAR(30) NOT NULL,
  service_status      VARCHAR(20) NOT NULL,
  replication_status  VARCHAR(30) NOT NULL DEFAULT 'N/A',
  INDEX idx_hostname_time (hostname, check_time)
);

-- inventory.yaml 기준 초기 데이터
INSERT INTO host_list (hostname, host_ip, cluster_type, role, service_name) VALUES
  ('mysql-84-source',   '192.168.56.201', 'replication', 'source',    'mysqld'),
  ('mysql-84-replica',  '192.168.56.202', 'replication', 'replica',   'mysqld'),
  ('mysql-ibc-router',  '192.168.56.210', 'ibc',         'router',    'mysqlrouter'),
  ('mysql-ibc-primary', '192.168.56.211', 'ibc',         'primary',   'mysqld'),
  ('mysql-ibc-sec01',   '192.168.56.212', 'ibc',         'secondary', 'mysqld'),
  ('mysql-ibc-sec02',   '192.168.56.213', 'ibc',         'secondary', 'mysqld'),
  ('mysql-84-backup',   '192.168.56.222', 'standalone',  'backup',    'mysqld')
ON DUPLICATE KEY UPDATE host_ip = VALUES(host_ip);

-- Oracle 헬스체크 대상 호스트 목록. healtch_check_oracle.sh 가 참조한다.
CREATE TABLE IF NOT EXISTS oracle_host_list (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  hostname        VARCHAR(64) NOT NULL UNIQUE,
  host_ip         VARCHAR(45) NOT NULL,
  role            ENUM('si','dg_primary','dg_standby','rac_node','rman') NOT NULL,
  oracle_sid      VARCHAR(30) DEFAULT NULL,
  db_unique_name  VARCHAR(30) DEFAULT NULL,
  enabled         TINYINT(1) NOT NULL DEFAULT 1,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- inventory.yaml 기준 초기 데이터 (oracle_sid는 lab 기본값 'orcl' 가정 — 실제 SID로 조정 필요)
INSERT INTO oracle_host_list (hostname, host_ip, role, oracle_sid, db_unique_name) VALUES
  ('orcl-19c-si',          '192.168.56.101', 'si',         'orcl',  NULL),
  ('orcl-19c-dg-primary',  '192.168.56.102', 'dg_primary', 'orcl',  NULL),
  ('orcl-19c-dg-standby',  '192.168.56.103', 'dg_standby', 'orcl',  NULL),
  ('orcl-19c-rac01',       '192.168.56.11',  'rac_node',   'orcl191', 'orcl'),
  ('orcl-19c-rac02',       '192.168.56.12',  'rac_node',   'orcl192', 'orcl'),
  ('orcl-19c-rac03',       '192.168.56.13',  'rac_node',   'orcl193', 'orcl'),
  ('orcl-19c-rman',        '192.168.56.199', 'rman',       NULL,    NULL)
ON DUPLICATE KEY UPDATE host_ip = VALUES(host_ip);

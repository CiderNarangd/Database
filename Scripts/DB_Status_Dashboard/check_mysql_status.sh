#!/usr/bin/env bash
#
# MySQL 랩 상태 대시보드용 점검 스크립트 (크론 전용, 비대화형)
#
# lab_dashboard.hosts(enabled=1)를 순회하며 서비스 상태(systemctl)와
# 복제 상태(performance_schema)를 점검해 lab_dashboard.checks에 적재한다.
# 신규 호스트가 생기면 hosts 테이블에 INSERT만 하면 자동으로 점검 대상에 포함된다.
#
# 크론 등록 예:
#   */5 * * * * /storage/scripts/check_mysql_status.sh >> /storage/scripts/logs/check_mysql_status.log 2>&1
#

set -uo pipefail

# cron은 기본 PATH(/sbin:/bin:/usr/sbin:/usr/bin)만 사용해 mysql 클라이언트(/usr/local/mysql/bin)를 못 찾는다.
export PATH="/usr/local/mysql/bin:${PATH}"

# ---- 로컬 lab_dashboard DB (Manager 호스트에 설치된 MySQL) ----
LOCAL_DB_HOST="localhost"
LOCAL_DB_USER="dashboard_writer"
LOCAL_DB_PASS="oralce"
LOCAL_DB_NAME="lab_dashboard"

# ---- 대상 MySQL 호스트 OS 계정 (systemctl 조회용 ssh) ----
SSH_USER="kinam"
SSH_PASS="oracle"
SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=5)

# ---- 대상 MySQL 호스트 DB 계정 (복제 상태 조회용) ----
MYSQL_USER="root"
MYSQL_PASS="oralce"

for bin in mysql sshpass; do
  command -v "$bin" >/dev/null 2>&1 || { echo "[FATAL] '$bin' 명령이 필요합니다. 설치 후 다시 실행하세요." >&2; exit 1; }
done

mysql_local() {
  MYSQL_PWD="$LOCAL_DB_PASS" mysql -h"$LOCAL_DB_HOST" -u"$LOCAL_DB_USER" -N -B "$@"
}

mysql_remote() {
  local ip=$1; shift
  MYSQL_PWD="$MYSQL_PASS" mysql -h"$ip" -u"$MYSQL_USER" --connect-timeout=5 -N -B "$@" 2>/dev/null
}

ssh_remote() {
  local ip=$1; shift
  SSHPASS="$SSH_PASS" sshpass -e ssh "${SSH_OPTS[@]}" "${SSH_USER}@${ip}" "$@" </dev/null 2>/dev/null
}

check_service_status() {
  local ip=$1 svc=$2 status
  status=$(ssh_remote "$ip" "systemctl is-active ${svc}")
  [ -z "$status" ] && status="unreachable"
  echo "$status"
}

# 단일 소스 복제(replica): performance_schema 기반 (MySQL 8.4)
check_replica_status() {
  local ip=$1 io_state sql_state
  io_state=$(mysql_remote "$ip" -e "SELECT SERVICE_STATE FROM performance_schema.replication_connection_status;")
  sql_state=$(mysql_remote "$ip" -e "SELECT SERVICE_STATE FROM performance_schema.replication_applier_status;")
  if [ -z "$io_state" ] || [ -z "$sql_state" ]; then
    echo "unreachable|"
  elif [ "$io_state" = "ON" ] && [ "$sql_state" = "ON" ]; then
    echo "ok|"
  else
    echo "error|io=${io_state:-NA},sql=${sql_state:-NA}"
  fi
}

# InnoDB Cluster (Group Replication) 멤버 상태
check_group_replication_status() {
  local ip=$1 state
  state=$(mysql_remote "$ip" -e "SELECT MEMBER_STATE FROM performance_schema.replication_group_members WHERE MEMBER_ID = @@server_uuid;")
  if [ -z "$state" ]; then
    echo "unreachable|"
  elif [ "$state" = "ONLINE" ]; then
    echo "ok|"
  else
    echo "error|${state}"
  fi
}

insert_check() {
  local hostname=$1 check_name=$2 status=$3 detail=$4
  mysql_local -D "$LOCAL_DB_NAME" -e \
    "INSERT INTO checks (hostname, check_name, status, detail) VALUES ('${hostname}','${check_name}','${status}','${detail}');"
}

run_status_check() {
  printf "%-20s %-13s %-12s %-25s\n" "HOSTNAME" "SERVICE" "SVC_STATUS" "REPL_STATUS"
  printf '%s\n' "--------------------------------------------------------------------"

  local fail_count=0
  local hostname host_ip role service_name svc_status repl_status repl_detail repl_raw
  while IFS=$'\t' read -r hostname host_ip role service_name; do
    [ -z "$hostname" ] && continue

    svc_status=$(check_service_status "$host_ip" "$service_name")
    insert_check "$hostname" "service" "$svc_status" ""

    case "$role" in
      replica)            repl_raw=$(check_replica_status "$host_ip") ;;
      primary|secondary)  repl_raw=$(check_group_replication_status "$host_ip") ;;
      *)                   repl_raw="n_a|" ;;
    esac
    repl_status=${repl_raw%%|*}
    repl_detail=${repl_raw#*|}
    insert_check "$hostname" "replication" "$repl_status" "$repl_detail"

    printf "%-20s %-13s %-12s %-25s\n" "$hostname" "$service_name" "$svc_status" "$repl_status"

    [ "$svc_status" != "active" ] && fail_count=$((fail_count + 1))
    case "$repl_status" in
      error|unreachable) fail_count=$((fail_count + 1)) ;;
    esac
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e "SELECT hostname, host_ip, role, service_name FROM hosts WHERE enabled = 1;")

  printf '%s\n' "--------------------------------------------------------------------"
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

#!/usr/bin/env bash
#
# MySQL Healtch check and management script
#
# 로컬 호스트 MySQL 에 있는 db_list.host_list 에서 조회한다 (스키마: db_list_schema.sql).
# 신규 호스트가 생기면 host_list 에 INSERT만 하면 자동으로 점검/관리 대상에 포함된다.
#

set -uo pipefail

# ---- 로컬 db_list DB (Manager 호스트에 설치된 MySQL) ----
LOCAL_DB_HOST="localhost"
LOCAL_DB_USER="root"
LOCAL_DB_PASS="oracle"
LOCAL_DB_NAME="db_list"

# ---- 대상 MySQL 호스트 OS 계정 (systemctl 조회용 ssh) ----
SSH_USER="kinam"
SSH_PASS="oracle"
SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=5)

# ---- 대상 MySQL 호스트 DB 계정 (복제 상태 조회용, 읽기 전용) ----
MYSQL_USER="prometheus"
MYSQL_PASS="oralce"

# ---- 대상 MySQL 호스트 DB 관리자 계정 (리플리케이션 시작 등 제어용) ----
ADMIN_USER="dba_user"
ADMIN_PASS="oralce"

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

# 리플리케이션 시작 등 관리자 권한이 필요한 원격 실행 (에러 메시지 보존)
mysql_remote_admin() {
  local ip=$1; shift
  MYSQL_PWD="$ADMIN_PASS" mysql -h"$ip" -u"$ADMIN_USER" --connect-timeout=5 -N -B "$@" 2>&1
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

# 단일 소스 복제(replica): performance_schema 기반, MySQL 8.4의 SHOW REPLICA STATUS 대체
check_replica_status() {
  local ip=$1 io_state sql_state
  io_state=$(mysql_remote "$ip" -e "SELECT SERVICE_STATE FROM performance_schema.replication_connection_status;")
  sql_state=$(mysql_remote "$ip" -e "SELECT SERVICE_STATE FROM performance_schema.replication_applier_status;")
  if [ -z "$io_state" ] || [ -z "$sql_state" ]; then
    echo "unreachable"
  elif [ "$io_state" = "ON" ] && [ "$sql_state" = "ON" ]; then
    echo "ok"
  else
    echo "error(io=${io_state:-NA},sql=${sql_state:-NA})"
  fi
}

# InnoDB Cluster (Group Replication) 멤버 상태
check_group_replication_status() {
  local ip=$1 state
  state=$(mysql_remote "$ip" -e "SELECT MEMBER_STATE FROM performance_schema.replication_group_members WHERE MEMBER_ID = @@server_uuid;")
  if [ -z "$state" ]; then
    echo "unreachable"
  elif [ "$state" = "ONLINE" ]; then
    echo "ok"
  else
    echo "error(${state})"
  fi
}

# 원격 호스트의 systemctl 서비스 시작/정지 (start|stop)
manage_service() {
  local ip=$1 svc=$2 action=$3
  ssh_remote "$ip" "sudo systemctl ${action} ${svc}"
}

# role x action(start|stop)에 따라 단일 소스 리플리케이션(replica) / Group Replication(primary, secondary) 분기
set_replication_state() {
  local ip=$1 role=$2 action=$3 out rc
  case "${role}:${action}" in
    replica:start)
      out=$(mysql_remote_admin "$ip" -e "START REPLICA;")
      ;;
    replica:stop)
      out=$(mysql_remote_admin "$ip" -e "STOP REPLICA;")
      ;;
    primary:start)
      out=$(mysql_remote_admin "$ip" -e \
        "SET GLOBAL group_replication_bootstrap_group=ON; START GROUP_REPLICATION; SET GLOBAL group_replication_bootstrap_group=OFF;")
      ;;
    secondary:start)
      out=$(mysql_remote_admin "$ip" -e "START GROUP_REPLICATION;")
      ;;
    primary:stop|secondary:stop)
      out=$(mysql_remote_admin "$ip" -e "STOP GROUP_REPLICATION;")
      ;;
    *)
      return 2
      ;;
  esac
  rc=$?
  [ "$rc" -ne 0 ] && echo "$out" >&2
  return "$rc"
}

# 리플리케이션 상세 상태 조회 (읽기 전용, prometheus 계정)
show_replication_detail() {
  local ip=$1 role=$2
  case "$role" in
    replica)
      mysql_remote "$ip" -e \
        "SELECT 'IO' AS thread, SERVICE_STATE, LAST_ERROR_MESSAGE FROM performance_schema.replication_connection_status
         UNION ALL
         SELECT 'SQL', SERVICE_STATE, LAST_ERROR_MESSAGE FROM performance_schema.replication_applier_status;"
      ;;
    primary|secondary)
      mysql_remote "$ip" -e \
        "SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members;"
      ;;
  esac
}

log_result() {
  local hostname=$1 service_name=$2 service_status=$3 repl_status=$4
  mysql_local -D "$LOCAL_DB_NAME" -e \
    "INSERT INTO health_check_log (hostname, service_name, service_status, replication_status) VALUES ('${hostname}','${service_name}','${service_status}','${repl_status}');"
}

run_status_check() {
  printf "%-20s %-13s %-12s %-25s\n" "HOSTNAME" "SERVICE" "SVC_STATUS" "REPL_STATUS"
  printf '%s\n' "--------------------------------------------------------------------"

  local fail_count=0
  local hostname host_ip role service_name svc_status repl_status
  while IFS=$'\t' read -r hostname host_ip role service_name; do
    [ -z "$hostname" ] && continue

    svc_status=$(check_service_status "$host_ip" "$service_name")

    case "$role" in
      replica)            repl_status=$(check_replica_status "$host_ip") ;;
      primary|secondary)  repl_status=$(check_group_replication_status "$host_ip") ;;
      *)                   repl_status="N/A" ;;
    esac

    printf "%-20s %-13s %-12s %-25s\n" "$hostname" "$service_name" "$svc_status" "$repl_status"
    log_result "$hostname" "$service_name" "$svc_status" "$repl_status"

    [ "$svc_status" != "active" ] && fail_count=$((fail_count + 1))
    case "$repl_status" in
      error*|unreachable) fail_count=$((fail_count + 1)) ;;
    esac
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e "SELECT hostname, host_ip, role, service_name FROM host_list WHERE enabled = 1;")

  printf '%s\n' "--------------------------------------------------------------------"
  if [ "$fail_count" -eq 0 ]; then
    echo "[OK] 모든 호스트 정상"
    return 0
  else
    echo "[WARN] 이상 감지 ${fail_count}건 (db_list.health_check_log 참고)"
    return 1
  fi
}

# 전체 호스트의 서비스를 일괄 시작/정지 (systemctl start|stop, ssh + sudo)
# start: source/primary -> secondary -> replica -> backup -> router 순
# stop : router -> backup -> replica -> secondary -> primary/source 순 (역순)
run_manage_all_services() {
  local action=$1 order_sql hostname host_ip role service_name fail_count=0

  if [ "$action" = "start" ]; then
    order_sql="FIELD(role,'source','primary','secondary','replica','backup','router')"
  else
    order_sql="FIELD(role,'router','backup','replica','secondary','primary','source')"
  fi

  while IFS=$'\t' read -r hostname host_ip role service_name; do
    [ -z "$hostname" ] && continue
    printf "[INFO] %-20s %-13s %s... " "$hostname" "$service_name" "$action"
    if manage_service "$host_ip" "$service_name" "$action"; then
      echo "OK"
    else
      echo "FAIL"
      fail_count=$((fail_count + 1))
    fi
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e \
    "SELECT hostname, host_ip, role, service_name FROM host_list WHERE enabled = 1 ORDER BY ${order_sql};")

  if [ "$fail_count" -eq 0 ]; then
    echo "[OK] 전체 서비스 ${action} 완료"
  else
    echo "[WARN] ${fail_count}건 ${action} 실패 (ssh 접속 또는 sudo 권한을 확인하세요)"
  fi
}

# 리플리케이션 대상 호스트(replica / primary / secondary)를 순회하며 시작/정지
# start: primary(그룹 부트스트랩) -> secondary(그룹 조인) -> replica(단일 소스) 순
# stop : secondary -> replica -> primary(그룹 리더는 마지막) 순
run_replication_action() {
  local action=$1 order_sql hostname host_ip role found=0 fail_count=0

  if [ "$action" = "start" ]; then
    order_sql="FIELD(role,'primary','secondary','replica')"
  else
    order_sql="FIELD(role,'secondary','replica','primary')"
  fi

  while IFS=$'\t' read -r hostname host_ip role; do
    [ -z "$hostname" ] && continue
    found=1
    printf "[INFO] %-20s (%s) 리플리케이션 %s... " "$hostname" "$role" "$action"
    if set_replication_state "$host_ip" "$role" "$action"; then
      echo "OK"
    else
      echo "FAIL"
      fail_count=$((fail_count + 1))
    fi
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e \
    "SELECT hostname, host_ip, role FROM host_list WHERE enabled = 1 AND role IN ('primary','secondary','replica') ORDER BY ${order_sql};")

  if [ "$found" -eq 0 ]; then
    echo "[INFO] 리플리케이션 대상 호스트가 없습니다."
  elif [ "$fail_count" -eq 0 ]; then
    echo "[OK] 리플리케이션 ${action} 완료"
  else
    echo "[WARN] ${fail_count}건 리플리케이션 ${action} 실패"
  fi
}

# 리플리케이션 대상 호스트의 상세 상태 조회 (일반 상태 점검보다 세부 정보)
run_replication_status_detail() {
  local hostname host_ip role found=0 out

  while IFS=$'\t' read -r hostname host_ip role; do
    [ -z "$hostname" ] && continue
    found=1
    echo "----- ${hostname} (${role}) -----"
    out=$(show_replication_detail "$host_ip" "$role")
    if [ -z "$out" ]; then
      echo "  unreachable"
    else
      echo "$out" | sed 's/^/  /'
    fi
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e \
    "SELECT hostname, host_ip, role FROM host_list WHERE enabled = 1 AND role IN ('primary','secondary','replica') ORDER BY FIELD(role,'primary','secondary','replica');")

  [ "$found" -eq 0 ] && echo "[INFO] 리플리케이션 대상 호스트가 없습니다."
}

show_menu() {
  echo "==================================================="
  echo " MySQL 헬스체크/관리 스크립트"
  echo "==================================================="
  echo " 1) 상태 점검 (status check)"
  echo " 2) DB 서비스 전체 시작"
  echo " 3) DB 서비스 전체 종료"
  echo " 4) 리플리케이션 시작"
  echo " 5) 리플리케이션 중지"
  echo " 6) 리플리케이션 상태 체크"
  echo " 7) 종료"
  echo "==================================================="
}

while true; do
  show_menu
  read -rp "선택> " choice
  case "$choice" in
    1) run_status_check ;;
    2) run_manage_all_services start ;;
    3) run_manage_all_services stop ;;
    4) run_replication_action start ;;
    5) run_replication_action stop ;;
    6) run_replication_status_detail ;;
    7) echo "종료합니다."; exit 0 ;;
    *) echo "[WARN] 1~7 중에서 선택하세요." ;;
  esac
  echo
done

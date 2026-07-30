#!/usr/bin/env bash
#
# Oracle Healtch check and management script
#
# 로컬 호스트 MySQL 에 있는 db_list.oracle_host_list 에서 조회한다 (스키마: db_list_schema.sql,
# oracle_sid/db_unique_name 컬럼은 실제 환경에 맞게 등록해야 한다).
#
# 필요 패키지(Manager 호스트): mysql client, sshpass
# 

set -uo pipefail

# ---- 로컬 db_list DB (Manager 호스트에 설치된 MySQL) ----
LOCAL_DB_HOST="localhost"
LOCAL_DB_USER="root"
LOCAL_DB_PASS="oracle"
LOCAL_DB_NAME="db_list"

# ---- 대상 Oracle 호스트 OS 계정 (ssh) ----
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

# 인스턴스 프로세스 상태 
check_instance_status() {
  local ip=$1 sid=$2 status
  if [ -z "$sid" ]; then
    status=$(ssh_remote "$ip" "echo reachable")
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
    echo "unreachable"; return
  fi
  role=${out%%|*}; mode=${out#*|}
  if [ "$role" = "PRIMARY" ] && [[ "$mode" == READ\ WRITE* ]]; then
    echo "ok"
  else
    echo "error(role=${role:-NA},mode=${mode:-NA})"
  fi
}

# Data Guard Standby: DATABASE_ROLE=PHYSICAL STANDBY + MRP(managed recovery) 적용 중 확인
check_dg_standby_status() {
  local ip=$1 sid=$2 out role mrp
  out=$(run_sql_remote "$ip" "$sid" "SELECT DATABASE_ROLE FROM V\$DATABASE;" | tail -1)
  if [ -z "$out" ]; then
    echo "unreachable"; return
  fi
  role="$out"
  mrp=$(run_sql_remote "$ip" "$sid" "SELECT STATUS FROM V\$MANAGED_STANDBY WHERE PROCESS LIKE 'MRP%';" | tail -1)
  if [ "$role" = "PHYSICAL STANDBY" ] && [ "$mrp" = "APPLYING_LOG" ]; then
    echo "ok"
  else
    echo "error(role=${role:-NA},mrp=${mrp:-NONE})"
  fi
}

# RAC 노드: 자신의 인스턴스 STATUS=OPEN 확인
check_rac_status() {
  local ip=$1 sid=$2 out
  out=$(run_sql_remote "$ip" "$sid" "SELECT STATUS FROM V\$INSTANCE;" | tail -1)
  if [ -z "$out" ]; then
    echo "unreachable"
  elif [ "$out" = "OPEN" ]; then
    echo "ok"
  else
    echo "error(${out:-NA})"
  fi
}

# role에 따라 상태 점검 함수 분기 (si/rman은 인스턴스 상태만, N/A)
check_role_status() {
  local ip=$1 sid=$2 role=$3
  case "$role" in
    dg_primary) check_dg_primary_status "$ip" "$sid" ;;
    dg_standby) check_dg_standby_status "$ip" "$sid" ;;
    rac_node)   check_rac_status "$ip" "$sid" ;;
    *)          echo "N/A" ;;
  esac
}

# 인스턴스 시작/종료 (si/dg_primary/dg_standby/rman: SQL*Plus startup/shutdown, rac_node: srvctl)
manage_instance() {
  local ip=$1 sid=$2 role=$3 dbname=$4 action=$5

  if [ -z "$sid" ]; then
    return 2
  fi

  if [ "$role" = "rac_node" ]; then
    ssh_remote "$ip" "export ORACLE_SID=${sid}; export ORAENV_ASK=NO; . oraenv >/dev/null 2>&1; srvctl ${action} instance -d ${dbname} -i ${sid}"
    return $?
  fi

  local sql out
  if [ "$action" = "start" ]; then
    sql="startup;"
  else
    sql="shutdown immediate;"
  fi
  out=$(run_sql_remote "$ip" "$sid" "$sql") || { echo "$out" >&2; return 1; }
  if echo "$out" | grep -qi "ORA-"; then
    echo "$out" >&2
    return 1
  fi
  return 0
}

# Data Guard 리플리케이션(=managed recovery) 시작/중지. standby에서만 의미가 있음.
set_replication_state() {
  local ip=$1 sid=$2 role=$3 action=$4 sql out rc

  if [ "$role" != "dg_standby" ]; then
    return 2
  fi
  if [ "$action" = "start" ]; then
    sql="ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;"
  else
    sql="ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;"
  fi
  out=$(run_sql_remote "$ip" "$sid" "$sql")
  rc=$?
  [ "$rc" -ne 0 ] && echo "$out" >&2
  echo "$out" | grep -qi "ORA-" && return 1
  return "$rc"
}

# Data Guard 상세 상태 (role/open_mode + MRP 적용 상태)
show_replication_detail() {
  local ip=$1 sid=$2 role=$3
  case "$role" in
    dg_primary|dg_standby)
      run_sql_remote "$ip" "$sid" \
        "SELECT 'ROLE/OPEN_MODE: '||DATABASE_ROLE||'/'||OPEN_MODE FROM V\$DATABASE;"
      run_sql_remote "$ip" "$sid" \
        "SELECT 'MRP: '||PROCESS||' '||STATUS||' seq='||SEQUENCE#||' delay='||NVL(TO_CHAR(DELAY_MINS),'0') FROM V\$MANAGED_STANDBY WHERE PROCESS LIKE 'MRP%';"
      ;;
    rac_node)
      run_sql_remote "$ip" "$sid" "SELECT 'INSTANCE: '||INSTANCE_NAME||' '||STATUS FROM V\$INSTANCE;"
      ;;
  esac
}

log_result() {
  local hostname=$1 service_name=$2 service_status=$3 dg_status=$4
  mysql_local -D "$LOCAL_DB_NAME" -e \
    "INSERT INTO health_check_log (hostname, service_name, service_status, replication_status) VALUES ('${hostname}','${service_name}','${service_status}','${dg_status}');"
}

run_status_check() {
  printf "%-24s %-10s %-12s %-30s\n" "HOSTNAME" "SID" "INSTANCE" "DG/RAC_STATUS"
  printf '%s\n' "--------------------------------------------------------------------------"

  local fail_count=0
  local hostname host_ip role sid dbname inst_status dg_status
  while IFS=$'\t' read -r hostname host_ip role sid dbname; do
    [ -z "$hostname" ] && continue
    [ "$sid" = "NULL" ] && sid=""
    [ "${dbname:-}" = "NULL" ] && dbname=""

    inst_status=$(check_instance_status "$host_ip" "$sid")
    dg_status=$(check_role_status "$host_ip" "$sid" "$role")

    printf "%-24s %-10s %-12s %-30s\n" "$hostname" "${sid:-N/A}" "$inst_status" "$dg_status"
    log_result "$hostname" "${sid:-N/A}" "$inst_status" "$dg_status"

    [[ "$inst_status" != "active" && "$inst_status" != "reachable" ]] && fail_count=$((fail_count + 1))
    case "$dg_status" in
      error*|unreachable) fail_count=$((fail_count + 1)) ;;
    esac
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e "SELECT hostname, host_ip, role, oracle_sid, db_unique_name FROM oracle_host_list WHERE enabled = 1;")

  printf '%s\n' "--------------------------------------------------------------------------"
  if [ "$fail_count" -eq 0 ]; then
    echo "[OK] 모든 호스트 정상"
    return 0
  else
    echo "[WARN] 이상 감지 ${fail_count}건 (db_list.health_check_log 참고)"
    return 1
  fi
}

# 전체 호스트 인스턴스 일괄 시작/종료
# start: si -> dg_primary -> dg_standby -> rac_node -> rman 순
# stop : rman -> rac_node -> dg_standby -> dg_primary -> si 순 (역순)
run_manage_all_services() {
  local action=$1 order_sql hostname host_ip role sid dbname fail_count=0

  if [ "$action" = "start" ]; then
    order_sql="FIELD(role,'si','dg_primary','dg_standby','rac_node','rman')"
  else
    order_sql="FIELD(role,'rman','rac_node','dg_standby','dg_primary','si')"
  fi

  while IFS=$'\t' read -r hostname host_ip role sid dbname; do
    [ -z "$hostname" ] && continue
    [ "$sid" = "NULL" ] && sid=""
    [ "${dbname:-}" = "NULL" ] && dbname=""
    if [ -z "$sid" ]; then
      printf "[INFO] %-20s N/A (관리 대상 인스턴스 없음)\n" "$hostname"
      continue
    fi
    printf "[INFO] %-20s (%s) %s... " "$hostname" "$sid" "$action"
    if manage_instance "$host_ip" "$sid" "$role" "$dbname" "$action"; then
      echo "OK"
    else
      echo "FAIL"
      fail_count=$((fail_count + 1))
    fi
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e \
    "SELECT hostname, host_ip, role, oracle_sid, db_unique_name FROM oracle_host_list WHERE enabled = 1 ORDER BY ${order_sql};")

  if [ "$fail_count" -eq 0 ]; then
    echo "[OK] 전체 인스턴스 ${action} 완료"
  else
    echo "[WARN] ${fail_count}건 ${action} 실패 (ssh 접속/oraenv/sysdba 권한을 확인하세요)"
  fi
}

# Data Guard standby의 managed recovery(리플리케이션) 시작/중지
run_replication_action() {
  local action=$1 hostname host_ip role sid dbname found=0 fail_count=0

  while IFS=$'\t' read -r hostname host_ip role sid dbname; do
    [ -z "$hostname" ] && continue
    [ "$sid" = "NULL" ] && sid=""
    [ "${dbname:-}" = "NULL" ] && dbname=""
    found=1
    printf "[INFO] %-20s (%s) 리플리케이션 %s... " "$hostname" "$role" "$action"
    if set_replication_state "$host_ip" "$sid" "$role" "$action"; then
      echo "OK"
    else
      echo "FAIL"
      fail_count=$((fail_count + 1))
    fi
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e \
    "SELECT hostname, host_ip, role, oracle_sid, db_unique_name FROM oracle_host_list WHERE enabled = 1 AND role = 'dg_standby';")

  if [ "$found" -eq 0 ]; then
    echo "[INFO] 리플리케이션(standby) 대상 호스트가 없습니다."
  elif [ "$fail_count" -eq 0 ]; then
    echo "[OK] 리플리케이션 ${action} 완료"
  else
    echo "[WARN] ${fail_count}건 리플리케이션 ${action} 실패"
  fi
}

# Data Guard / RAC 상세 상태 조회
run_replication_status_detail() {
  local hostname host_ip role sid dbname found=0 out

  while IFS=$'\t' read -r hostname host_ip role sid dbname; do
    [ -z "$hostname" ] && continue
    [ "$sid" = "NULL" ] && sid=""
    [ "${dbname:-}" = "NULL" ] && dbname=""
    found=1
    echo "----- ${hostname} (${role}) -----"
    out=$(show_replication_detail "$host_ip" "$sid" "$role")
    if [ -z "$out" ]; then
      echo "  unreachable"
    else
      echo "$out" | sed 's/^/  /'
    fi
  done < <(mysql_local -D "$LOCAL_DB_NAME" -e \
    "SELECT hostname, host_ip, role, oracle_sid, db_unique_name FROM oracle_host_list WHERE enabled = 1 AND role IN ('dg_primary','dg_standby','rac_node') ORDER BY FIELD(role,'dg_primary','dg_standby','rac_node');")

  [ "$found" -eq 0 ] && echo "[INFO] Data Guard/RAC 대상 호스트가 없습니다."
}

show_menu() {
  echo "==================================================="
  echo " Oracle 헬스체크/관리 스크립트"
  echo "==================================================="
  echo " 1) 상태 점검 (status check)"
  echo " 2) DB 인스턴스 전체 시작"
  echo " 3) DB 인스턴스 전체 종료"
  echo " 4) 리플리케이션 시작 (DG standby managed recovery)"
  echo " 5) 리플리케이션 중지 (DG standby managed recovery)"
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

#!/bin/bash
# ============================================================
#  Mysql 9.7.0 Auto Install Script
#  OS   : OEL 9.4
#  User : mysql
#
# /storage/downloads file check & need dir
# mkdir -p /storage/downloads
# chmod -R 777 /storage
# ============================================================

set -euo pipefail
 
# ============================================================
# Define Path & Variables
# ============================================================

DATA_DIR=/u01/mysql/${HOSTNAME}/DATA
LOG_DIR=/u01/mysql/${HOSTNAME}/ADMIN
BIN_DIR=/u01/mysql/${HOSTNAME}/BINLOG
IBLOG_DIR=/u01/mysql/${HOSTNAME}/IBLOG

MYSQL_TAR=/storage/downloads/mysql-9.7.0-linux-glibc2.28-x86_64.tar.xz   # check tar file name & dir
EXTRACT_DIR="mysql-9.7.0-linux-glibc2.28-x86_64"

MYSQL_HOME=/usr/local/mysql
MYSQL_BASE=/usr/local

MYSQL_USER=mysql
MYSQL_GROUP=mysql


LOG=/storage/downloads/mysql_install_$(date +%Y%m%d_%H%M%S).log
 
# ============================================================
# Functions
# ============================================================
log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
die()  { echo "[ERROR] $*" | tee -a "$LOG"; exit 1; }
run_as_mysql() { 
	#su - ${OS_USER} -c "$1" >> "$LOG" 2>&1; 
	su - ${OS_USER} -c "$1" 2>&1 | tee -a "$LOG";
	}
 
# ============================================================
# [1] root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start Mysql 9.7 Auto Installer ==="
echo -e "\n"

# ============================================================
# [2] Create User & Group
# ============================================================
log "[STEP 2] Make Create Mysql User&Group"

groupadd mysql
useradd -r -g mysql -s /bin/false mysql

echo -e "\n"
 
# ============================================================
# [3] 디렉토리 생성 및 권한
# ============================================================
log "[STEP 3] Make Directory & Change Ownership"
mkdir -p ${DATA_DIR} ${LOG_DIR} \
         ${BIN_DIR} ${IBLOG_DIR} 

chown -R ${MYSQL_USER}:${MYSQL_GROUP} /u01
chmod -R 775 /u01
log "Make Directory & Change ownership Complete"
echo -e "\n"

# ============================================================
# [4] my.cnf 생성
# ============================================================
log "[STEP 4] Set my.cnf"
cat << EOF | tee /etc/my.cnf

[client]
port            = 3306
socket          = /u01/mysql/${HOSTNAME}/DATA/mysql.sock
#password       = your_password

[mysqld]
#data dir
basedir         = /usr/local/mysql
datadir         = /u01/mysql/${HOSTNAME}/DATA
socket          = /u01/mysql/${HOSTNAME}/DATA/mysql.sock

log-error       = /u01/mysql/${HOSTNAME}/ADMIN/error_log.log
log-bin         = /u01/mysql/${HOSTNAME}/BINLOG/mysql-bin

innodb_log_group_home_dir = /u01/mysql/${HOSTNAME}/IBLOG
innodb_data_home_dir      = /u01/mysql/${HOSTNAME}/DATA

EOF
chown ${OS_USER}:${MYSQL_GROUP} /etc/my.cnf
chmod 775 -R /etc/my.cnf

echo -e "\n"
# ============================================================
# [5] Extract Mysql Tar..
# ============================================================
 log "[STEP 5]  Extract Mysql tar.. -> ${ORACLE_HOME}"
 
 [[ -f ${MYSQL_TAR} ]] || die "No ZIP file: ${MYSQL_TAR}"
 
 # change own
 chown ${MYSQL_USER}:${MYSQL_GROUP} "${MYSQL_TAR}" || die "Failed to change compressed file ownership"
 
 tar -xvf ${MYSQL_TAR}/${} -C ${MYSQL_BASE}
 ln -s ${MYSQL_BASE}/${ORIGIN_DIR} ${MYSQL_HOME}

 log "Complete Extract"
 echo -e "\n"





# ============================================================
# [10] DBCA Silent - DB 생성 (Archive Mode 포함)
# ============================================================
log "[STEP 9] DBCA Silent - DB Create"
run_as_oracle "
source /home/${OS_USER}/.bash_profile
dbca -silent -createDatabase \
  -templateName General_Purpose.dbc \
  -gdbName ${DB_NAME} \
  -sid ${DB_SID} \
  -responseFile NO_VALUE \
  -characterSet ${CHARSET} \
  -nationalCharacterSet ${NCHARSET} \
  -sysPassword '${SYS_PASSWORD}' \
  -systemPassword '${SYSTEM_PASSWORD}' \
  -datafileDestination ${DATA_DIR} \
  -recoveryAreaDestination ${FRA_DIR} \
  -recoveryAreaSize ${FRA_SIZE} \
  -enableArchive true \
  -memoryMgmtType AUTO_SGA \
  -totalMemory ${TOTAL_MEMORY} \
  -redoLogFileSize 200 \
  -storageType FS \
  -emConfiguration NONE \
  -sampleSchema false 
" || die "DBCA failed. log check: $LOG"

log "DBCA Create DB Complete"

echo -e "\n"
# ============================================================
# [11] /etc/oratab 등록 확인 & autostart 설정 ## 자동시작 필요없으면 패스해도될듯
# ============================================================
log "[STEP 10] oratab autostart set"
sed -i "s|^${DB_SID}:.*|${DB_SID}:${ORACLE_HOME}:N|" /etc/oratab

echo -e "\n"
# ============================================================
# [12] 설치 후 검증
# ============================================================
log "[STEP 11] Installation Verification"
run_as_oracle "
source /home/${OS_USER}/.bash_profile
sqlplus -s / as sysdba << 'SQLEOF'
SET PAGESIZE 20 LINESIZE 100
SELECT instance_name, status, database_status FROM v\$instance;
SELECT name, log_mode, open_mode FROM v\$database;
ARCHIVE LOG LIST;
EXIT;
SQLEOF
" | tee -a "$LOG"

echo -e "\n"
# ============================================================
# [13] oracle 계정패스워드 변경
# ============================================================
log "[STEP 12] Change Oracle account passwd"
echo "oracle:oracle" | chpasswd || die "Oracle account password change failed"
log "Complete Oracle account change passwd"

echo -e "\n"
# ============================================================
log "=== Install Complete ==="
log "Log File	: $LOG"
log "SID       	: ${DB_SID}"
log "ORACLE_HOME: ${ORACLE_HOME}"
log "Archive   	: ${ARCHIVE_DIR}"





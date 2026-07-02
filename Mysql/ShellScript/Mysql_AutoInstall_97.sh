#!/bin/bash
# ============================================================
#  Mysql 9.7.0 Auto Install Script
#  OS   : OEL 9.4
#  User : mysql
#
# /storage/downloads file check & need dir
# mkdir -p /storage/downloads
# chmod -R 777 /storage
#
# systemctl 등록해서 사용할시 dba계정 생성 및 권한 부여 필요함
# 해당 스크립트는 설치까지만!!
# ============================================================

set -euo pipefail
 
# ============================================================
# Define Path & Variables
# ============================================================

DATA_DIR=/u01/mysql/${HOSTNAME}/DATA
LOG_DIR=/u01/mysql/${HOSTNAME}/ADMIN
BIN_DIR=/u01/mysql/${HOSTNAME}/BINLOG
IBLOG_DIR=/u01/mysql/${HOSTNAME}/IBLOG
RELAY_DIR=/u01/mysql/${HOSTNAME}/IBLOG

MYSQL_TAR=/storage/downloads/mysql-9.7.0-linux-glibc2.28-x86_64.tar.xz   # check tar file name & dir
EXTRACT_DIR="mysql-9.7.0-linux-glibc2.28-x86_64"

MYSQL_HOME=/usr/local/mysql
MYSQL_BASE=/usr/local

MYSQL_USER=mysql
MYSQL_GROUP=mysql
ROOT_PASSWD=oracle

LOG=/storage/downloads/mysql_install_$(date +%Y%m%d_%H%M%S).log
 
# ============================================================
# Functions
# ============================================================
log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
die()  { echo "[ERROR] $*" | tee -a "$LOG"; exit 1; }

# ============================================================
# [1] root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start Mysql 9.7 Auto Installer ==="
echo -e "\n"

# ============================================================
# [2] Create User & Group
# ============================================================
log "[STEP 1] Make Create Mysql User&Group"

if ! getent group ${MYSQL_GROUP} > /dev/null; then
    groupadd ${MYSQL_GROUP} 2>&1 | tee -a "$LOG"
fi

if ! getent passwd ${MYSQL_USER} > /dev/null; then
    useradd -r -g ${MYSQL_GROUP} -s /bin/false ${MYSQL_USER} 2>&1 | tee -a "$LOG"
fi

echo -e "\n"
 
# ============================================================
# [3] 디렉토리 생성 및 권한
# ============================================================
log "[STEP 2] Make Directory & Change Ownership"
mkdir -p ${DATA_DIR} ${LOG_DIR} ${BIN_DIR} ${IBLOG_DIR} ${RELAY_DIR} 2>&1 | tee -a "$LOG"

chown -R ${MYSQL_USER}:${MYSQL_GROUP} /u01 2>&1 | tee -a "$LOG"
chmod -R 775 /u01 2>&1 | tee -a "$LOG"
log "Make Directory & Change ownership Complete"
echo -e "\n"

# ============================================================
# [4] my.cnf 생성
# ============================================================
log "[STEP 3] Set my.cnf"
if [ -f /etc/my.cnf ]; then
    mv /etc/my.cnf /etc/my.cnf.bak_$(date +%Y%m%d_%H%M%S)
fi

cat << EOF | tee /etc/my.cnf | tee -a "$LOG"

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
chown ${MYSQL_USER}:${MYSQL_GROUP} /etc/my.cnf 
chmod 644 /etc/my.cnf 

log "Create /etc/my.cnf Complete.."

echo -e "\n"
# ============================================================
# [5] Extract Mysql Tar..
# ============================================================
log "[STEP 4] Extract Mysql tar.. -> ${MYSQL_BASE}" 
[[ -f ${MYSQL_TAR} ]] || die "No ZIP file: ${MYSQL_TAR}"
 
rm -f ${MYSQL_HOME}
rm -rf ${MYSQL_BASE}/${EXTRACT_DIR}

tar -xvf ${MYSQL_TAR} -C ${MYSQL_BASE} 
ln -sv ${MYSQL_BASE}/${EXTRACT_DIR} ${MYSQL_HOME} 

chown ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_HOME} 
chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_BASE}/${EXTRACT_DIR}

log "Complete Extract and Symbolic Link"
echo -e "\n"

# ============================================================
# [6] Initializing Mysql 
# ============================================================
 log "[STEP 5]  Initializing Mysql.."
 
 ${MYSQL_HOME}/bin/mysqld --defaults-file=/etc/my.cnf --initialize --user=${MYSQL_USER} 

log "Temp Password Extract"
TEMP_PASS=$(awk '/A temporary password is generated/ {print $NF}' ${LOG_DIR}/error_log.log)
log "Temp Password : ${TEMP_PASS}"

log "Initializing Complete.."
echo -e "\n"

# ============================================================
# [12] 설치 후 검증
# ============================================================
log "[STEP 6] Installation Verification"

log "Run Mysql Daemon..."
${MYSQL_HOME}/bin/mysqld_safe --defaults-file=/etc/my.cnf --user=${MYSQL_USER} & 

sleep 10

${MYSQL_HOME}/bin/mysql --defaults-file=/etc/my.cnf -u root -p"${TEMP_PASS}" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWD}';" 
log "Root Password Update Complete."

log "Verification Check..."
${MYSQL_HOME}/bin/mysql --defaults-file=/etc/my.cnf -u root -p"${ROOT_PASSWD}" -t << 'MYEOF' 2>&1 | tee -a "$LOG"  
SELECT * FROM performance_schema.global_status 
WHERE VARIABLE_NAME = 'UPTIME';

SELECT @@version, @@version_comment, @@hostname;

MYEOF
#shutdown;
# ============================================================
log "=== Install Complete ==="
log "Log File	: $LOG"





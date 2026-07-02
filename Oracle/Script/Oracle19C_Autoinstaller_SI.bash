#!/bin/bash
# ============================================================
#  Oracle 19c Auto Install Script
#  OS   : OEL 7.9
#  Mode : DB Engine + DBCA (FS 기반)
#  User : oracle / oinstall / dba
#
# /storage/downloads file check & need dir
# mkdir -p /storage/downloads
# chmod -R 777 /storage
# ============================================================

set -euo pipefail
 
# ============================================================
# Define Path & Variables
# ============================================================
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
ORACLE_HOME_T=/u01/app/oracle/product/19.3.0/dbhome_t
ORACLE_INVENTORY=/u01/app/oraInventory
#ORACLE_ZIP=/storage/downloads/Oracle19C_Engine.zip   # check zip file name & dir
ORACLE_ZIP=/storage/downloads/19c_db_linux.zip   # check zip file name & dir
ORACLE_PREINSTALL=/storage/downloads/oracle-database-preinstall-19c-1.0-2.el8.x86_64.rpm

DB_UNIQUE_NAME=ORCL
DB_SID=ORCL
DB_NAME=ORCL
DB_DOMAIN=""
SYS_PASSWORD=oracle
SYSTEM_PASSWORD=oracle
 
CHARSET=AL32UTF8
NCHARSET=AL16UTF16
TOTAL_MEMORY=3072                              # MB
 
## Data & Log Directory Path 
DATA_DIR=/u02/${DB_UNIQUE_NAME}/
FRA_DIR=/u03/fast_recovery_area/${DB_UNIQUE_NAME}/
ARCHIVE_DIR=/u03/oradata/${DB_SID}/archive/
FRA_SIZE=10240                                 # MB
 
OS_USER=oracle
OS_GROUP_INV=oinstall
OS_GROUP_DBA=dba
OS_GROUP_OPER=oper
OS_GROUP_BKUP=backupdba
OS_GROUP_DGDBA=dgdba
OS_GROUP_KMDBA=kmdba
 
LOG=/storage/downloads/oracle_install_$(date +%Y%m%d_%H%M%S).log
 
# ============================================================
# Functions
# ============================================================
log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
die()  { echo "[ERROR] $*" | tee -a "$LOG"; exit 1; }
run_as_oracle() { 
	#su - ${OS_USER} -c "$1" >> "$LOG" 2>&1; 
	su - ${OS_USER} -c "$1" 2>&1 | tee -a "$LOG";
	}
 
# ============================================================
# [1] root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start Oracle 19c Auto Installer ==="
echo -e "\n"
 
# ============================================================
# [2] OS 패키지 설치
# ============================================================
log "[STEP 1] Install OS Package "
#yum install -y oracle-database-preinstall-19c >> "$LOG" 2>&1 || die "Faild Install Preinstall Package.."
yum install -y oracle-database-preinstall-19c 2>&1 | tee -a "$LOG" || die "Failed Install Preinstall Package.."
echo -e "\n"
# ============================================================
# [3] 디렉토리 생성 및 권한
# ============================================================
log "[STEP 2] Make Directory"
mkdir -p ${ORACLE_HOME} ${ORACLE_INVENTORY} \
         ${DATA_DIR} ${FRA_DIR} ${ARCHIVE_DIR}  

chown -R ${OS_USER}:${OS_GROUP_INV} /u0{1..3}
chmod -R 775 /u0{1..3}
log "Make Directory Complete"
echo -e "\n"
# ============================================================
# [4] 커널 파라미터 (sysctl)
# ============================================================
log "[STEP 3] Set Kernel Parameter"
{
    sed -e '/^\s*#/d' -e '/^\s*$/d' /etc/sysctl.conf 
} 2>&1 | tee -a "$LOG"

echo -e "\n"
# ============================================================
# [5] 리소스 제한 확인 
# ============================================================
log "[STEP 4] Check Resource Limit "
{
    sed -e '/^\s*#/d' -e '/^\s*$/d' /etc/security/limits.d/oracle-database-preinstall-19c.conf
} 2>&1 | tee -a "$LOG"

echo -e "\n"
# ============================================================
# [6] oracle 환경변수 (.bash_profile)
# ============================================================
log "[STEP 5] Set Environment variables"
cat << EOF | tee -a /home/${OS_USER}/.bash_profile

# Oracle Environment
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_SID=${DB_SID}
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export SQLPATH=/home/oracle/scripts:/storage/Scripts
umask 022
EOF
chown ${OS_USER}:${OS_GROUP_INV} /home/${OS_USER}/.bash_profile

echo -e "\n"
# ============================================================
# [7] zip 압축 해제 
# ============================================================
 log "[STEP 6] Oracle zip file Unzip... -> ${ORACLE_HOME}"
 
 [[ -f ${ORACLE_ZIP} ]] || die "No ZIP file: ${ORACLE_ZIP}"
 
 # change own
 chown oracle:oinstall "${ORACLE_ZIP}" || die "Failed to change compressed file ownership"
 
 run_as_oracle "unzip -q ${ORACLE_ZIP} -d ${ORACLE_HOME}"
 
 log "Complete Unzip"
 echo -e "\n"
# ============================================================
# [8] DB Engine Silent Install (response file)
# ============================================================

log "[STEP 7] DB Engine Silent Install"
RESP_FILE=/tmp/db_install.rsp
cat > ${RESP_FILE} << EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=${OS_GROUP_INV}
INVENTORY_LOCATION=${ORACLE_INVENTORY}
ORACLE_HOME=${ORACLE_HOME}
ORACLE_BASE=${ORACLE_BASE}
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=${OS_GROUP_DBA}
oracle.install.db.OSOPER_GROUP=${OS_GROUP_OPER}
oracle.install.db.OSBACKUPDBA_GROUP=${OS_GROUP_BKUP}
oracle.install.db.OSDGDBA_GROUP=${OS_GROUP_DGDBA}
oracle.install.db.OSKMDBA_GROUP=${OS_GROUP_KMDBA}
oracle.install.db.OSRACDBA_GROUP=${OS_GROUP_DBA}
oracle.install.db.rootconfig.executeRootScript=false
EOF
chown ${OS_USER}:${OS_GROUP_INV} ${RESP_FILE}

run_as_oracle "${ORACLE_HOME}/runInstaller -silent \
  -responseFile ${RESP_FILE} \
  -ignorePrereqFailure \
  -waitforcompletion" \
  || log "WARN: runInstaller exit non-zero (Must check log file)"
  
 echo -e "\n" 
# ============================================================
# [9] root 스크립트 실행
# ============================================================
log "[STEP 8] Excute root Script "
${ORACLE_INVENTORY}/orainstRoot.sh >> "$LOG" 2>&1
${ORACLE_HOME}/root.sh >> "$LOG" 2>&1
log "Complete Excute root Scripts "
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





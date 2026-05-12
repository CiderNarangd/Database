#!/bin/bash
# ============================================================
#  Oracle 19c Auto Install Script
#  OS   : OEL 7.9
#  Mode : DB Engine + DBCA (FS 기반)
#  User : oracle / oinstall / dba
# ============================================================
 
set -euo pipefail
 
# ============================================================
# Define Path & Variables
# ============================================================
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
ORACLE_HOME_T=/u01/app/oracle/product/19.3.0/dbhome_t
ORACLE_INVENTORY=/u01/app/oraInventory
ORACLE_ZIP=/storage/downloads/Oracle19C_Engine.zip   # check zip file name & dir
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
run_as_oracle() { su - ${OS_USER} -c "$1" >> "$LOG" 2>&1; }
 
# ============================================================
# [2] root 확인
# ============================================================
[[ $EUID -ne 0 ]] && die "root 로 실행하세요."
log "=== Oracle 19c 자동 설치 시작 ==="
 
# ============================================================
# [3] OS 패키지 설치
# ============================================================
log "[STEP 1] OS 패키지 설치 // Test중이라 패스"
#yum install -y oracle-database-preinstall-19c >> "$LOG" 2>&1 \
#||die "Faild Install Preinstall Package.." 

# ============================================================
# [5] 디렉토리 생성 및 권한
# ============================================================
log "[STEP 3] 디렉토리 생성 Test중이라 임의로 생성"
mkdir -p /u03/test
chown -R oracle:oinstall /u03
chmod -R 775 /u03
# mkdir -p ${ORACLE_HOME} ${ORACLE_INVENTORY} \
#          ${DATA_DIR} ${FRA_DIR} ${ARCHIVE_DIR} \ 

# chown -R ${OS_USER}:${OS_GROUP_INV} /u0{1..3}
# chmod -R 775 /u01{1..3}
echo -e "\n"
# ============================================================
# [6] 커널 파라미터 (sysctl)
# ============================================================
log "[STEP 4] 커널 파라미터 설정"
{
    sed -e '/^\s*#/d' -e '/^\s*$/d' /etc/sysctl.conf 
} 2>&1 | tee -a "$LOG"

echo -e "\n"
# ============================================================
# [7] 리소스 제한 확인 
# ============================================================
log "[STEP 5] Check Limit "
{
    sed -e '/^\s*#/d' -e '/^\s*$/d' /etc/security/limits.d/oracle-database-preinstall-19c.conf
} 2>&1 | tee -a "$LOG"

echo -e "\n"
# ============================================================
# [8] oracle 환경변수 (.bash_profile)
# ============================================================
log "[STEP 6] 환경변수 설정"
cat << EOF | tee -a /home/${OS_USER}/.bash_profile2

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
chown ${OS_USER}:${OS_GROUP_INV} /home/${OS_USER}/.bash_profile2

echo -e "\n"
# ============================================================
# [9] zip 압축 해제 ###### NEED New host
# ============================================================
# log "[STEP 7] Oracle zip 압축 해제 -> ${ORACLE_HOME_T}"
# [[ -f ${ORACLE_ZIP} ]] || die "ZIP 파일 없음: ${ORACLE_ZIP}"
# run_as_oracle "unzip -q ${ORACLE_ZIP} -d ${ORACLE_HOME_T}"
 
# ============================================================
# [10] DB Engine Silent Install (response file)
# ============================================================


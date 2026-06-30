#!/bin/bash

# ============================================================
#  Oracle
#  OS   	: OEL 7.9
#  DB 		: Oracle 19C 
#  backup	: rman
#  User 	: oracle
#
#  백업 완료 후 2차 백업 서버로 백업본 전송 
#  백업 본 전송후 2차 백업 서버 catalog db에 backup history insert
#    
#  ssh 인증작업 선행 필수
#  ssh-keygen -t rsa -b 4096 
#  ssh-copy-id -i ~/.ssh/id_rsa.pub oracle@rman_host
# 
# ============================================================
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/dbhome_1
export ORACLE_SID=orcl                                   
export PATH=$ORACLE_HOME/bin:$PATH
export LANG=C

HOST_NAME=$(hostname)

BACKUP_BASE_DIR="/u03/backup"
DATE=$(date +%Y%m%d)
BACKUP_DIR="${BACKUP_BASE_DIR}/${DATE}"    

mkdir -p "${BACKUP_DIR}"


rman target / catalog ruser/ruser@rman_remote << EOF

CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 3 DAYS;

CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BACKUP_DIR}/ctl_%F';

RUN {
    ALLOCATE CHANNEL ch01 DEVICE TYPE DISK FORMAT '${BACKUP_DIR}/db_%d_%U_%t';
    ALLOCATE CHANNEL ch02 DEVICE TYPE DISK FORMAT '${BACKUP_DIR}/db_%d_%U_%t';

    BACKUP DATABASE PLUS ARCHIVELOG FORMAT '${BACKUP_DIR}/arch_%d_%U_%t';

    RELEASE CHANNEL ch01;
    RELEASE CHANNEL ch02;
}

CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
DELETE NOPROMPT OBSOLETE;     
DELETE NOPROMPT EXPIRED BACKUP;

EOF

## Delete Old Backup dir
find "${BACKUP_BASE_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime +3 -exec rm -rf {} \;

RMAN_HOST="orcl-19c-rman" 
RMAN_BACKUP_DIR="/u03/backup/${HOST_NAME}/"

ssh oracle@${RMAN_HOST} "mkdir -p ${RMAN_BACKUP_DIR}"
scp -r "${BACKUP_DIR}" oracle@${RMAN_HOST}:${RMAN_BACKUP_DIR}/
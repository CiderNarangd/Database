#!/bin/bash

# ============================================================
#  Mysql Full backup Shell Script
#  OS   	: Rocky Linux 9.8
#  DB 		: mysql8.4.8
#  backup	: xtrabackup 8.4.0-6
#  User 	: kinam
#
#  백업 완료 후 2차 백업 서버로 백업본 전송 
#  백업 본 전송후 2차 백업 서버 catalog db에 backup history insert
#
#  1일 1풀백업
#  /usr/local/xtrabackup/bin
#  /storage/logs directory needs
#
#  0 6 * * * /bin/sh /${PATH}/script.sh
#
# ============================================================

# Config

DATE=$(date +%Y%m%d)
LOG=/storage/logs/my_full_backup_$(date +%Y%m%d).log

MY_CNF=/etc/my.cnf
HOST_NAME=$(hostname)

## Test
HOST_NAME=mysqltemplate

BACKUP_USER="xtrabackup"
BACKUP_DIR=/u01/mysql/${HOST_NAME}/BACKUP/${DATE}_full

BACKUP_RETENTION_DAYS=3 

# 2차 백업 서버 정보
REMOTE_USER="user"
REMOTE_HOST="mysql-84-backup"
REMOTE_TARGET_DIR="/backupdir/${HOST_NAME}"

# ============================================================
# Functions
# ============================================================
log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
newline() { echo "" | tee -a "$LOG"; }

clean_old_backup(){

	log "Cleaning up backups older than $BACKUP_RETENTION_DAYS days..."
	if [ -d "${BACKUP_BASE_DIR}" ]; then
        log "Scanning local backup directory: ${BACKUP_BASE_DIR}"
        find "${BACKUP_BASE_DIR}" -maxdepth 1 -type d -name "*_full" -mtime +${BACKUP_RETENTION_DAYS} -exec rm -rf {} \; -print | tee -a "$LOG"
    fi
}

main(){
	log "================================================"
	
	log "=== $(date +%Y%m%d) Mysql Daily Full Backup Start ==="
	newline
	
	log "=== Full Backup Start : $(date +%Y%m%d_%H:%M:%S)==="
	
	BACKUP_START_DATE=$(date "+%Y-%m-%d %H:%M:%S")
	
	mkdir -p ${BACKUP_DIR} | tee -a "$LOG"
	xtrabackup \
		--defaults-file=${MY_CNF} \
		--backup \
		--host=localhost \
		--user=${BACKUP_USER} \
		--password='oracle' \
		--no-lock \
		--parallel=4 \
		--no-version-check \
		--target-dir=${BACKUP_DIR} |& tee -a "$LOG"
		
	log "=== Full Backup Complete : $(date +%Y%m%d_%H:%M:%S) ==="
	newline
	
	log "================================================"
	
	log "=== Prepare Start : $(date +%Y%m%d_%H:%M:%S) ======"
	
	xtrabackup --prepare --parallel=4 --target-dir=${BACKUP_DIR} |& tee -a "$LOG"
	
	
	BACKUP_END_DATE=$(date "+%Y-%m-%d %H:%M:%S")
	log "=== Prepare Complete : $(date +%Y%m%d_%H:%M:%S) ==="
	newline
	
	BACKUP_SIZE=$(du -sb "${BACKUP_DIR}"| cut -f1) 
	
	log "================================================"
	
	#### Transfer to Secondary Backup Server ####
	
	log "=== Start Send Backup to Secondary Backup Server : $(date +%Y%m%d_%H:%M:%S) ==="
	newline
	
	ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_TARGET_DIR}"
	scp -rp ${BACKUP_DIR} ${REMOTE_USER}@${REMOTE_HOST}:"${REMOTE_TARGET_DIR}"
	
	ssh "${REMOTE_USER}@${REMOTE_HOST}" mysql --login-path=kinam --host=127.0.0.1 <<EOF
	INSERT INTO backup_history.history (
		host_name, 
		backup_type, 
		start_date, 
		end_date, 
		backup_size, 
		backup_path, 
		created_date
	) VALUES (
		'${HOST_NAME}', 
		0, 
		'${BACKUP_START_DATE}', 
		'${BACKUP_END_DATE}', 
		${BACKUP_SIZE}, 
		'${REMOTE_TARGET_DIR}/${DATE}_full', 
		NOW()
	);
EOF
	
	log "=== Transfer to Secondary Backup Server complete: $(date +%Y%m%d_%H:%M:%S) ==="
	newline
	
	log "================================================"

}

main
clean_old_backup
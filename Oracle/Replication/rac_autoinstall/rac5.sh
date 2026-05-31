#!/bin/bash
# ============================================================
# Create DB Instance Using DBCA
# 
# ============================================================

# ============================================================
# Global Variables
# ============================================================
LOG=/storage/downloads/dbca_install_$(date +%Y%m%d_%H%M%S).log

DBCA_RSP=/storage/downloads/dbca.rsp

# ============================================================
# Functions
# ============================================================
log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; echo "" | tee -a "$LOG"; }
die()  { echo "" | tee -a "$LOG"; echo "[ERROR] $*" | tee -a "$LOG"; exit 1; }
newline() { echo "" | tee -a "$LOG"; }

run_as_oracle() { 
	su - oracle -c "$1" 2>&1 | tee -a "$LOG";
	}
	

# ============================================================
# DBCA Install
# ============================================================	

log "Create Database Start...."
newline

run_as_oracle "source /home/oracle/.bash_profile; dbca -silent -createDatabase \
  -responseFile ${DBCA_RSP} -ignorePreReqs" || die "DBCA failed. log check: $LOG"

log "Complete Create Database Instance"
newline

run_as_oracle "
source /home/oracle/.bash_profile
sqlplus -s / as sysdba << 'SQLEOF'
SET PAGESIZE 20 LINESIZE 100
SELECT instance_name, status, database_status FROM v\$instance;
SELECT name, log_mode, open_mode FROM v\$database;
ARCHIVE LOG LIST;
EXIT;
SQLEOF
" | tee -a "$LOG"


log "Create Database complete "

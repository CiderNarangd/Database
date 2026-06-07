#!/bin/bash
# ============================================================
# Create DB Instance Using DBCA
# 
# ============================================================

# ============================================================
# Global Variables
# ============================================================
source /storage/downloads/common.sh
LOG=/storage/downloads/dbca_install_$(date +%Y%m%d_%H%M%S).log

# ============================================================
# [1] root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start RAC Auto Installer Part4 - Craete Database Using DBCA"
echo -e "\n"

# ============================================================
# DBCA Install
# ============================================================	

log "Create Database Start...."
newline

chown oracle:dba ${DBCA_RSP}

run_as_oracle "source /home/oracle/.bash_profile; dbca -silent -createDatabase \
  -responseFile ${DBCA_RSP} -ignorePreReqs -enableArchive true -archiveLogMode AUTO -archiveLogDest +FRA" || die "DBCA failed. log check: $LOG"

log "Complete Create Database Instance"
newline

log "validation chk"
run_as_oracle "
source /home/oracle/.bash_profile
sqlplus -s / as sysdba << 'SQLEOF'
SET PAGESIZE 20 LINESIZE 100
SELECT instance_name, status, database_status FROM v\$instance;
SELECT name, log_mode, open_mode FROM v\$database;
ARCHIVE LOG LIST;
SELECT gi.inst_id,\
       gi.instance_name,\
       gi.host_name,\
       gi.status,\
       gd.db_unique_name,\
       gd.open_mode,\
       gd.log_mode\
FROM   gv$instance  gi\
       JOIN gv$database gd ON gi.inst_id = gd.inst_id\
ORDER BY gi.inst_id;
SELECT COUNT(DISTINCT inst_id)        AS instance_count,\
       COUNT(DISTINCT db_unique_name)  AS db_count,\
       MAX(db_unique_name)             AS db_name\
FROM   gv$database;
EXIT;
SQLEOF
" | tee -a "$LOG"


log "Create Database complete "

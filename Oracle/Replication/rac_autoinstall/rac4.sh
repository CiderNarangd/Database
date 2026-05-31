#!/bin/bash
# ============================================================
# Db Engine Install 19C
# /storage/downloads
# ============================================================

# ============================================================
# Global Variables
# ============================================================
LOG=/storage/downloads/oracle_install_$(date +%Y%m%d_%H%M%S).log

ORACLE_ZIP=/storage/downloads/Oracle19C_Engine.zip
DB_RSP=/storage/downloads/db.rsp

ORACLE_BASE=/u02/app/oracle
ORACLE_HOME=/u02/app/oracle/product/19.3.0/dbhome_1


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
# Make DIR & Permission Change & Unzip
# ============================================================

run_as_oracle "mkdir -p /u02/app/oracle/product/19.3.0/dbhome_1"
chown -R oracle:dba /u02
chmod -R 775 /u02

ssh root@oel7rac2 "mkdir -p /u02/app/oracle/product/19.3.0/dbhome_1 && chown -R oracle:dba /u02 && chmod -R 775 /u02"

chown oracle:dba ${ORACLE_ZIP}

newline
log "Unzip Start"
newline
run_as_oracle "unzip -q ${ORACLE_ZIP} -d ${ORACLE_HOME}"
newline
log "Unzip Finish"
newline


log "Complete Permission change & unzip"


# ============================================================
# Env variables
# ============================================================	

#RAC1 
cat << 'EOF' | tee -a /home/oracle/.bash_profile

export LANG=C
export ORACLE_BASE=/u02/app/oracle
export ORACLE_HOME=/u02/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=ORA191
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export PATH=$ORACLE_HOME/bin:$PATH

alias oh='cd $ORACLE_HOME'
umask 022
EOF

#RAC2로 전송 및 SID 수정
scp /home/oracle/.bash_profile root@oel7rac2:/home/oracle/.bash_profile
ssh root@oel7rac2 "chown oracle:dba /home/oracle/.bash_profile"
ssh root@oel7rac2 "sed -i 's/ORACLE_SID=ORA191/ORACLE_SID=ORA192/' /home/oracle/.bash_profile"

log "Env Variable complete"

# ============================================================
# ORACLE Install
# ============================================================	
log "Install Oracle Engine 19C"

run_as_oracle "${ORACLE_HOME}/runInstaller -silent \
  -responseFile ${DB_RSP} \
  -ignorePrereqFailure \
  -waitforcompletion" 


log "Run Root Script "

/u02/app/oracle/product/19.3.0/dbhome_1/root.sh 2>&1 | tee -a "$LOG"
ssh root@oel7rac2 "/u02/app/oracle/product/19.3.0/dbhome_1/root.sh" 2>&1 | tee -a "$LOG"

log "Oracle Engine 19C Install Complete"
newline
log "Next is Create DB Instance..."
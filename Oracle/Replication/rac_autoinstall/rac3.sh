#!/bin/bash
# ============================================================
# Grid Install
# /storage/downloads
# ============================================================

# ============================================================
# Global Variables
# ============================================================

LOG=/storage/downloads/grid_install_$(date +%Y%m%d_%H%M%S).log

GRID_ZIP=/storage/downloads/Oracle19C_Grid.zip
ORACLE_ZIP=/storage/downloads/Oracle19C_Engine.zip
GRID_RSP=/storage/downloads/grid.rsp

GRID_HOME=/u01/app/19.3.0/grid

# ============================================================
# Functions
# ============================================================
log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; echo "" | tee -a "$LOG"; }
die()  { echo "" | tee -a "$LOG"; echo "[ERROR] $*" | tee -a "$LOG"; exit 1; }
newline() { echo "" | tee -a "$LOG"; }

run_as_oracle() { 
	su - oracle -c "$1" 2>&1 | tee -a "$LOG";
	}
	
run_as_grid() { 
	su - grid -c "$1" 2>&1 | tee -a "$LOG";
	}
	
	
# ============================================================
# Permission Change & Unzip
# ============================================================

chown grid:dba ${GRID_ZIP}
chown grid:dba ${GRID_RSP}

newline
log "Unzip Start"
newline
run_as_grid "unzip -q ${GRID_ZIP} -d ${GRID_HOME}"
newline
log "Unzip Finish"
newline


log "Complete Permission change & unzip"

# ============================================================
# Env variables
# ============================================================	

#RAC1 
cat << 'EOF' | tee -a /home/grid/.bash_profile

export LANG=C
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export ORACLE_SID=+ASM1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export PATH=$ORACLE_HOME/bin:$PATH

alias oh='cd $ORACLE_HOME'
alias dbs='cd $ORACLE_HOME/dbs'
alias net='cd $ORACLE_HOME/network/admin'
umask 022
EOF

#RAC2로 전송 및 SID 수정
scp /home/grid/.bash_profile root@oel7rac2:/home/grid/.bash_profile
ssh root@oel7rac2 "chown grid:dba /home/grid/.bash_profile"
ssh root@oel7rac2 "sed -i 's/ORACLE_SID=+ASM1/ORACLE_SID=+ASM2/' /home/grid/.bash_profile"

log "Env Variable complete"

# ============================================================
# Grid Install
# ============================================================	
log "Install Grid Infrastructure"
run_as_grid "${GRID_HOME}/gridSetup.sh -silent -responseFile ${GRID_RSP} -ignorePrereqFailure -waitforcompletion"


log "Run Root Script "
/u01/app/oraInventory/orainstRoot.sh 2>&1 | tee -a "$LOG"
ssh root@oel7rac2 "/u01/app/oraInventory/orainstRoot.sh" 2>&1 | tee -a "$LOG"


${GRID_HOME}/root.sh 2>&1 | tee -a "$LOG"
ssh root@oel7rac2 "${GRID_HOME}/root.sh" 2>&1 | tee -a "$LOG"

log "Grid Infrastructure installatino Complete"


# ============================================================
# ASMCA Create DISK GROUP
# ============================================================	

#asmca -silent -createDiskGroup \
#  -diskGroupName FRA \
# -diskList /dev/oracleasm/disks/FRA01,/dev/oracleasm/disks/FRA02 \
#  -redundancy EXTERNAL \
#  -au_size 4

# ============================================================
# Check Validation
# ============================================================	

run_as_grid "source /home/grid/.bash_profile"
run_as_grid "crsctl check cluster -all"
run_as_grid "crsctl check crs"
run_as_grid "crsctl stat res -t"
run_as_grid "asmcmd lsdg"

log "Do ASMCA Setting"
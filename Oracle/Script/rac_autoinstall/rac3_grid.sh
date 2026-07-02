#!/bin/bash
# ============================================================
# Grid Install
# /storage/downloads
# ============================================================
#
# grid.rsp file check oraInvenctory & $ORACLE_BASE
#
# ============================================================
# Global Variables
# ============================================================
source /storage/downloads/common.sh

LOG=/storage/downloads/grid_install_$(date +%Y%m%d_%H%M%S).log

# ============================================================
#  root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start RAC Auto Installer Part2 - GRID Install"
echo -e "\n"
	
	
# ============================================================
# Permission Change & Unzip
# ============================================================

log "permission change & unzip"

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

log "Env Variable set start"

NODE_NUM=1

while read -r HOSTNAME <&3
do
	[ -z "$HOSTNAME" ] && continue

    cat > /tmp/grid_profile << EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH	
export LANG=C
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export ORACLE_SID=+ASM${NODE_NUM}
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export PATH=\$ORACLE_HOME/bin:\$PATH

alias oh='cd \$ORACLE_HOME'
alias dbs='cd \$ORACLE_HOME/dbs'
alias net='cd \$ORACLE_HOME/network/admin'
umask 022
EOF

    if [ "$NODE_NUM" -eq 1 ]; then
        cp /tmp/grid_profile /home/grid/.bash_profile
        chown grid:dba /home/grid/.bash_profile
    else
        scp -q /tmp/grid_profile root@${HOSTNAME}:/home/grid/.bash_profile
        ssh -n root@${HOSTNAME} "chown grid:dba /home/grid/.bash_profile"
    fi

    NODE_NUM=$((NODE_NUM + 1))

done 3< "$HOSTS_LIST"

log "Env Variable set complete"

# ============================================================
# Grid Install
# ============================================================	
log "Install Grid Infrastructure - RAC Cluster"
run_as_grid "${GRID_HOME}/gridSetup.sh -silent -responseFile ${GRID_RSP} -ignorePrereqFailure -waitforcompletion"
[ $? -eq 0 ] || die "Grid Setup Failed"

NODE_NUM=1

log "Run Root Script [oraInstRoot.sh] Start"
while read -r HOSTNAME <&3
do
	
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
		log "Run Root Script [orainstRoot.sh] rac${NODE_NUM} node"
		[[ -x "${ORA_INVEN}/orainstRoot.sh" ]] || die "orainstRoot.sh not found in rac1 node : ${ORA_INVEN}/orainstRoot.sh"
		${ORA_INVEN}/orainstRoot.sh 2>&1 | tee -a "$LOG"
		log "rac1 node : orainstRoot.sh Complete"
	else
		log "Run Root Script [orainstRoot.sh] rac${NODE_NUM} node "
		ssh -n root@${HOSTNAME} "[[ -x ${ORA_INVEN}/orainstRoot.sh ]]" || die "orainstRoot.sh not found in rac${NODE_NUM} node : ${ORA_INVEN}/orainstRoot.sh"
		ssh -n root@${HOSTNAME} "${ORA_INVEN}/orainstRoot.sh" 2>&1 | tee -a "$LOG"
		log "rac${NODE_NUM} node : orainstRoot.sh Complete"
	fi
	
	NODE_NUM=$((NODE_NUM + 1))
	
done 3< "$HOSTS_LIST"

log "Run Root Script [oraInstRoot.sh] Complete"

log "=================================================="

log "Run Root Script [root.sh] Start.."
NODE_NUM=1
while read -r HOSTNAME <&3
do
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
		log "Run Root Script [root.sh] rac${NODE_NUM} node"
		[[ -x "${GRID_HOME}/root.sh" ]] || die "root.sh not found in rac1 node : ${GRID_HOME}/root.sh"
		${GRID_HOME}/root.sh 2>&1 | tee -a "$LOG"
		log "rac${NODE_NUM} node : root.sh Complete"
	else
		log "Run Root Script [root.sh] rac2 node "
		ssh -n root@${HOSTNAME} "[[ -x ${GRID_HOME}/root.sh ]]" || die "root.sh not found in rac2 node : ${GRID_HOME}/root.sh"
		ssh -n root@${HOSTNAME} "${GRID_HOME}/root.sh" 2>&1 | tee -a "$LOG"
		log "rac${NODE_NUM} node : root.sh Complete"
	fi
	
	NODE_NUM=$((NODE_NUM + 1))
	
done 3< "$HOSTS_LIST"

log "Run Root Script [root.sh] Complete"


log "Grid Infrastructure installation Complete"

# ============================================================
# ASMCA Create DISK GROUP
# ============================================================	

# 필요시 셋팅해서 주석해제
log "Add +FRA ASM Disk Group "

run_as_grid "asmca -silent -creatediskgroup \
  -diskgroupname FRA \
  -disklist /dev/oracleasm/disks/ASMDISK01 \
  -redundancy external \
  -au_size 4" | tee -a "$LOG"
  
log "+FRA ASM Disk Group Add Complete "

# ============================================================
# Check Validation
# ============================================================	
log "Validatino Chk"

run_as_grid "crsctl check cluster -all"
run_as_grid "crsctl check crs"
run_as_grid "crsctl stat res -t"
run_as_grid "asmcmd lsdg"

log "Do ASMCA Setting"


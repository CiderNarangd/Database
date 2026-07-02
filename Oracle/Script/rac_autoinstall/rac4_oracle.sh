#!/bin/bash
# ============================================================
# Db Engine Install 19C
# /storage/downloads
# ============================================================

# ============================================================
# Global Variables
# ============================================================
source /storage/downloads/common.sh
LOG=/storage/downloads/oracle_install_$(date +%Y%m%d_%H%M%S).log

# ============================================================
# [1] root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start RAC Auto Installer Part3 - Oracle Engine"
echo -e "\n"


# ============================================================
# Make DIR & Permission Change & Unzip
# ============================================================

log "Mkdir & Permission change & unzip start"

NODE_NUM=1

while read -r HOSTNAME <&3
do
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
        run_as_oracle "mkdir -p ${ORACLE_HOME}"
		chown -R oracle:dba /u02
		chmod -R 775 /u02
    else
		ssh -n root@${HOSTNAME} "mkdir -p ${ORACLE_HOME} && chown -R oracle:dba /u02 && chmod -R 775 /u02"
    fi

    NODE_NUM=$((NODE_NUM + 1))

done 3< "$HOSTS_LIST"
log "mkdir complete"


chown oracle:dba ${ORACLE_ZIP}
chown oracle:dba ${DB_RSP}

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


log "Env Variable set start"

NODE_NUM=1

while read -r HOSTNAME <&3
do
	[ -z "$HOSTNAME" ] && continue
    cat > /tmp/oracle_profile << EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin
	
export LANG=C
export ORACLE_BASE=/u02/app/oracle
export ORACLE_HOME=/u02/app/oracle/product/19.3.0/dbhome_1
export ORACLE_SID=ORA19${NODE_NUM}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export PATH=$ORACLE_HOME/bin:$PATH

alias oh='cd $ORACLE_HOME'
alias dbs='cd \$ORACLE_HOME/dbs'
alias net='cd \$ORACLE_HOME/network/admin'
umask 022

EOF

    if [ "$NODE_NUM" -eq 1 ]; then
        cp /tmp/oracle_profile /home/oracle/.bash_profile
        chown oracle:dba /home/oracle/.bash_profile
    else
        scp -q /tmp/oracle_profile root@${HOSTNAME}:/home/oracle/.bash_profile
        ssh -n root@${HOSTNAME} "chown oracle:dba /home/oracle/.bash_profile"
    fi

    NODE_NUM=$((NODE_NUM + 1))

done 3< "$HOSTS_LIST"

log "Env Variable set complete"

# ============================================================
# ORACLE Install
# ============================================================	
log "Install Oracle Engine 19C"

run_as_oracle "${ORACLE_HOME}/runInstaller -silent \
  -responseFile ${DB_RSP} \
  -ignorePrereqFailure \
  -waitforcompletion" 

log "Run Root Script [root.sh] Start.."

log "========================================"

NODE_NUM=1
while read -r HOSTNAME <&3
do
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
		log "Run Root Script [root.sh] rac${NODE_NUM} node"
		[[ -x "${ORACLE_HOME}/root.sh" ]] || die "root.sh not found in rac${NODE_NUM} node : ${ORACLE_HOME}/root.sh"
		${ORACLE_HOME}/root.sh 2>&1 | tee -a "$LOG"
		log "rac${NODE_NUM} node : root.sh Complete"
	else
		log "Run Root Script [root.sh] rac${NODE_NUM} node "
		ssh root@${HOSTNAME} "[[ -x ${ORACLE_HOME}/root.sh ]]" || die "root.sh not found in rac${NODE_NUM} node : ${ORACLE_HOME}/root.sh"
		ssh root@${HOSTNAME} "${ORACLE_HOME}/root.sh" 2>&1 | tee -a "$LOG"
		log "rac${NODE_NUM} node : root.sh Complete"
	fi
	
	NODE_NUM=$((NODE_NUM + 1))
	
done 3< "$HOSTS_LIST"

log "Run Root Script [root.sh] Complete"

log "Oracle Engine 19C Install Complete"
newline
log "Next is Create DB Instance..."
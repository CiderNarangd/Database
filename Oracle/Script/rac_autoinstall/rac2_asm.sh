#!/bin/bash
source /storage/downloads/common.sh

LOG=/storage/downloads/asm_$(date +%Y%m%d_%H%M%S).log

ROOT_DISK="sda"
### using lsblk commnad must check root disk

# =========================
#  root Check
# =========================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start RAC Auto Installer Part2 - ASM Partitioning"
echo -e "\n"

# ===============
#  SSh Set
# ===============
log "Account SSH Set.. Input Password "   

HOST_LIST_PARSE=$(tr '\n' ' ' < ${HOSTS_LIST})

log "Root Account ssh set "     
./sshUserSetup.sh \
-user root \
-hosts "$HOST_LIST_PARSE" \
-advanced \
-noPromptPassphrase | tee -a "$LOG"

log "oracle Account ssh set "
./sshUserSetup.sh \
-user oracle \
-hosts "$HOST_LIST_PARSE" \
-advanced \
-noPromptPassphrase | tee -a "$LOG"

log "grid Account ssh set "  
./sshUserSetup.sh \
-user grid \
-hosts "$HOST_LIST_PARSE" \
-advanced \
-noPromptPassphrase | tee -a "$LOG"


# ==============================
#  ASM Partitioning
# ==============================

log "oracleasm configure start.."

echo "" >> ${HOSTS_LIST} # 강제 개행 추가


NODE_NUM=1
while read -r HOSTNAME <&3
do
	echo "NODE ${NODE_NUM} config start"
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
		/usr/sbin/oracleasm configure -u grid -g dba -e -b -s y | tee -a "$LOG"
	else
		ssh -n root@${HOSTNAME} "/usr/sbin/oracleasm configure -u grid -g dba -e -b -s y" | tee -a "$LOG"
	fi
	
	NODE_NUM=$((NODE_NUM + 1))
done 3< "$HOSTS_LIST"

newline


log "oracleasm init start.."
NODE_NUM=1
while read -r HOSTNAME <&3
do

	echo "NODE ${NODE_NUM} init start"
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
		/usr/sbin/oracleasm init  | tee -a "$LOG"
	else
		ssh -n root@${HOSTNAME} "/usr/sbin/oracleasm init" | tee -a "$LOG"
	fi
	
	NODE_NUM=$((NODE_NUM + 1))
done 3< "$HOSTS_LIST"

newline

log "oracleasm disk partitioning.."

DISK_NUM=1

for d in {a..z}
do
    disk="sd$d"

    [[ ! -b /dev/$disk ]] && continue
    [[ "$disk" == "$ROOT_DISK" ]] && continue
	[[ -b /dev/${disk}1 ]] && continue
	
    echo "Partitioning : $disk"
	
	parted -s /dev/$disk mklabel gpt
	parted -s /dev/$disk mkpart primary 0% 100%
	
	partprobe /dev/$disk
	udevadm settle
	
	#pvcreate /dev/${disk}1

	ASM_NAME=$(printf "ASMDISK%02d" "$DISK_NUM")
	
	oracleasm createdisk "$ASM_NAME" /dev/${disk}1
	((DISK_NUM++))

done

log "oracleasm scan disks & listdisks.."
NODE_NUM=1
while read -r HOSTNAME <&3
do
	echo "NODE ${NODE_NUM} scan start"
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
		oracleasm scandisks | tee -a "$LOG"
	else
		ssh -n root@${HOSTNAME} "oracleasm scandisks" | tee -a "$LOG"
	fi
	
	NODE_NUM=$((NODE_NUM + 1))
done 3< "$HOSTS_LIST"


NODE_NUM=1
while read -r HOSTNAME <&3
do

	echo "NODE ${NODE_NUM} list start"
	[ -z "$HOSTNAME" ] && continue
	if [ "$NODE_NUM" -eq 1 ]; then
		oracleasm listdisks | tee -a "$LOG"
	else
		ssh -n root@${HOSTNAME} "oracleasm listdisks" | tee -a "$LOG"
	fi
	
	NODE_NUM=$((NODE_NUM + 1))
done 3< "$HOSTS_LIST"

lsblk
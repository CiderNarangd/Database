#!/bin/bash
# ============================================================
#  Oracle 19c Auto Install Script _1
#  OS   : OEL 7.9
#  Mode : Grid RAC
#  User : oracle / dba 
#
# /storage/downloads file check & need dir
# mkdir -p /storage/downloads
# chmod -R 777 /storage
# 19cgrid, 19cengine zip 
#
# Script 실행전 공유 디스크 셋팅 및 파티셔닝 사전 설정 필수
# Network Setting 사전 설정 필수
#
# 두번째 노드 머신은 첫번째 머신으로부터 복제해서 생성
#
# 양쪽 ssh 작업 필수
# 해당 스크립트에서 oracle계정은 os 설치하면서 생성했다고 가정
# 
# ============================================================


# Global variables
LOG=/storage/downloads/Pre_configured_$(date +%Y%m%d_%H%M%S).log

GRID_ZIP=/storage/downloads/19c_grid_linux.zip
ORACLE_ZIP=/storage/downloads/19c_db_linux.zip


# ============================================================
# Functions
# ============================================================
#log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
#die()  { echo "[ERROR] $*" | tee -a "$LOG"; exit 1; }

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
# [1] root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start RAC Auto Installer Part1 - GRID"
echo -e "\n"

# ============================================================
# [2] File Check
# ============================================================

#Test
touch /storage/downloads/19c_db_linux.zip
touch /storage/downloads/19c_grid_linux.zip

[ -f "$GRID_ZIP" ]   || die "Grid zip not found: $GRID_ZIP"
[ -f "$ORACLE_ZIP" ] || die "Oracle zip not found: $ORACLE_ZIP"


# ============================================================
# [2] OS 패키지 설치
# ============================================================
log "[STEP 1] Install OS Package "


yum install -y oracle-database-preinstall-19c 2>&1 | tee -a "$LOG" || die "Failed Install Preinstall Package.."
echo -e "\n"

yum install -y ntp 2>&1 | tee -a "$LOG" || die "Failed Install NTP Package.."
echo -e "\n"

yum list *oracleasm* 2>&1 | tee -a "$LOG" 
echo -e "\n"

yum install -y oracleasm-support 2>&1 | tee -a "$LOG" || die "Failed Install oracleasm-support Package.."
echo -e "\n"

yum install -y kmod-oracleasm 2>&1 | tee -a "$LOG" || die "Failed Install kmod-oracleasm Package.."
echo -e "\n"

## Change ntpd option change

#ntpd enable & start / Change option
sed -i 's/^OPTIONS=.*/OPTIONS="-g -x"/' /etc/sysconfig/ntpd 2>&1 | tee -a "$LOG"
systemctl enable ntpd && systemctl start ntpd

#Kill Avahi daemon
systemctl disable avahi-daemon && systemctl stop avahi-daemon

# ============================================================
# [3] Account Set
# ============================================================
log "Create Account"

useradd -s /bin/bash -g dba grid
usermod -g dba oracle
groupdel oracle

#Change Password
log "Chnage Password"
#echo "oracle:oracle" | chpasswd || die "oracle account password change failed"
echo "grid:grid" | chpasswd || die "grid account password change failed"
log "Complete Grid account change passwd"


## ============================================================
# [3] Mkdir
# ============================================================
log "Make Grid & Oracle Direcstory"

#u01 - grid
#u02 - oracle

mkdir -p /u01/app/19.3.0/grid 		  #ORACLE_HOME
mkdir -p /u01/app/grid				  #ORACLE_BASE  	
chown -R grid:dba /u01
chmod -R 775 /u01

mkdir -p /u02/app/oracle			  #ORACLE_BASE
mkdir -p /u02/app/oraInventory
chown -R oracle:dba /u02
chmod -R 775 /u02/app


## ============================================================
# [3] host set
# ============================================================

# Func Test
log "[STEP] Configure /etc/hosts"
cp /etc/hosts /etc/hosts.bak
cat >> /etc/hosts << 'EOF'

### Public
192.168.56.10   oel7rac1       
192.168.56.11   oel7rac2       

### Virtual
192.168.56.20   oel7rac1-vip   
192.168.56.21   oel7rac2-vip   
### Scan
192.168.56.100  oel7rac-scan 

### Private
192.168.10.11  oel7rac1-priv
192.168.10.12  oel7rac2-priv
EOF

cat /etc/hosts | tee -a "$LOG"

echo -e "\n"

hostnamectl set-hostname oel7rac1 2>&1 | tee -a "$LOG"				
hostnamectl status 2>&1 | tee -a "$LOG"
echo -e "\n"

## ============================================================
# [3] Spec Check
# ============================================================
grep MemTotal /proc/meminfo | tee -a "$LOG"
grep SwapTotal /proc/meminfo | tee -a "$LOG"
df -h /tmp/ | tee -a "$LOG"

sed -e '/^\s*#/d' -e '/^\s*$/d' /etc/security/limits.d/oracle-database-preinstall-19c.conf | tee -a "$LOG"
sed -e '/^\s*#/d' -e '/^\s*$/d' /etc/sysctl.d/99-oracle-database-preinstall-19c-sysctl.conf | tee -a "$LOG"

cat >> /etc/security/limits.conf << 'EOF'

grid       soft     nofile     4096
grid       hard     nofile     65536
grid       soft     nproc      16384
grid       hard     nproc      16384
grid       soft     stack      10240
grid       hard     stack      32768
grid       soft     memlock    3145728
grid       hard     memlock    3145728

EOF
tail -20 /etc/security/limits.conf | tee -a "$LOG"

newline
log "Restart the Host"


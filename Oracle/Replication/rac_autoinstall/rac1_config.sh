#!/bin/bash
source /storage/downloads/common.sh

# Global variables
LOG=/storage/downloads/Pre_configured_$(date +%Y%m%d_%H%M%S).log


# ============================================================
# root Check
# ============================================================
[[ $EUID -ne 0 ]] && die "Must Excute Root."
log "=== Start RAC Auto Installer Part1 - Congigure"
echo -e "\n"

# ============================================================
# File Check
# ============================================================

# Test
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
log "Set NTPD Option & systemctl set"
sed -i 's/^OPTIONS=.*/OPTIONS="-g -x"/' /etc/sysconfig/ntpd 2>&1 | tee -a "$LOG"
systemctl enable ntpd && systemctl start ntpd

#Kill Avahi daemon
log "kill & disable avahi-daemon"
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

GRID_HOME=/u01/app/19.3.0/grid
GRID_BASE=/u01/app/grid

ORACLE_BASE=/u02/app/oracle

mkdir -p ${GRID_HOME} 		  			#ORACLE_HOME
mkdir -p ${GRID_BASE}				  	#ORACLE_BASE  	
chown -R grid:dba /u01
chmod -R 775 /u01

mkdir -p ${ORACLE_BASE}			  		#ORACLE_BASE
chown -R oracle:dba /u02
chmod -R 775 /u02


## ============================================================
# [3] host set
# ============================================================

# Func Test
log "[STEP] Configure /etc/hosts"
cp /etc/hosts /etc/hosts.bak

if [ -f "$HOSTS_FILE" ]; then
    cat "$HOSTS_FILE" >> /etc/hosts
else
    echo "ERROR: $HOSTS_FILE not found"
    exit 1
fi

cat /etc/hosts | tee -a "$LOG"

echo -e "\n"

# hostnamectl set-hostname oel7rac1 2>&1 | tee -a "$LOG"				
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
log "Next is Clone Machine / Network&Hostname Setting / Shared Storage Setting"


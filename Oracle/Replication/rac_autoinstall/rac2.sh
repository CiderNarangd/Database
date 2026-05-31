rac2

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

3개의 랜카드 사용
1- public
2- Private
3- External

rac1 종료후
machine 복제

rac2 hostname 변경 및 네트워크 상태 확인 및 수정
hostnamectl set-hostname oel7rac2

shutdown -h 0

추가디스크 작업

D:\oracle_rac\rac_1\DATA01~05.vdi

DATA 10GB * 3 01~03
FRA  10GB * 2 04~05

양쪽 호스트 attach 해주고

둘다 start

1.Configure // All nodes
/usr/sbin/oracleasm configure -u grid -g dba -e -b -s y
/usr/sbin/oracleasm configure 

2. kernel module loading  // All nodes
/usr/sbin/oracleasm init 

[root@oel7rac2 ~]# /usr/sbin/oracleasm init
Creating /dev/oracleasm mount point: /dev/oracleasm
Loading module "oracleasm": oracleasm
Configuring "oracleasm" to use device logical block size
Mounting ASMlib driver filesystem: /dev/oracleasm

3. Disk Partition // Rac1 Nodes

bcdef
fdisk /dev/sdb                           n-p-엔터-엔터-엔터-w
fdisk /dev/sdc                           n-p-엔터-엔터-엔터-w
fdisk /dev/sdd                           n-p-엔터-엔터-엔터-w
fdisk /dev/sde                           n-p-엔터-엔터-엔터-w
fdisk /dev/sdf                           n-p-엔터-엔터-엔터-w

pvcreate /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1 /dev/sdf1

or 
pvcreate /dev/sdb1
pvcreate /dev/sdc1
pvcreate /dev/sdd1
pvcreate /dev/sde1
pvcreate /dev/sdf1

  Physical volume "/dev/sdb1" successfully created.
  Physical volume "/dev/sdc1" successfully created.
  Physical volume "/dev/sdd1" successfully created.
  Physical volume "/dev/sde1" successfully created.
  Physical volume "/dev/sdf1" successfully created.


4.ASM Disk 할당 // RAC1 NODES

oracleasm createdisk DATA01 /dev/sdb1
oracleasm createdisk DATA02 /dev/sdc1
oracleasm createdisk DATA03 /dev/sdd1
oracleasm createdisk FRA01 /dev/sde1
oracleasm createdisk FRA02 /dev/sdf1

oracleasm listdisks
DATA01
DATA02
DATA03
FRA01
FRA02

5.Scan Disk // ALL NODES
oracleasm scandisks

[root@oel7rac1 downloads]# oracleasm scandisks
Reloading disk partitions: done
Cleaning any stale ASM disks...
Scanning system for ASM disks...

[root@oel7rac2 ~]# oracleasm scandisks
Reloading disk partitions: done
Cleaning any stale ASM disks...
Scanning system for ASM disks...
Instantiating disk "FRA02"
Instantiating disk "DATA01"
Instantiating disk "DATA03"
Instantiating disk "DATA02"
Instantiating disk "FRA01"



// grid oracle root 서로 ssh key작업

--RAC1
su - oracle
ssh-keygen -t rsa -N ''    
ssh-copy-id oracle@oel7rac2
ssh-copy-id oracle@oel7rac1

su - grid
ssh-keygen -t rsa -N ''    
ssh-copy-id grid@oel7rac2  
ssh-copy-id grid@oel7rac1  

su - root
ssh-keygen -t rsa -N ''    
ssh-copy-id root@oel7rac2  
ssh-copy-id root@oel7rac1  

--RAC2

su - oracle
ssh-keygen -t rsa -N ''    
ssh-copy-id oracle@oel7rac2
ssh-copy-id oracle@oel7rac1

su - grid
ssh-keygen -t rsa -N ''    
ssh-copy-id grid@oel7rac2  
ssh-copy-id grid@oel7rac1  

su - root
ssh-keygen -t rsa -N ''    
ssh-copy-id root@oel7rac2  
ssh-copy-id root@oel7rac1  



//Validate Command
--grid
crsctl check cluster -all
olsnodes -t -n
crsctl stat res -t
asmcmd lsdg
srvctl status database -d ORA19
srvctl config database -d ORA19

SELECT instance_name, host_name, status FROM gv$instance;



srvctl stop database -d ORA19

--rac1 root
/u01/app/19.3.0/grid/bin/crsctl stop crs

--rac2 root
/u01/app/19.3.0/grid/bin/crsctl stop crs
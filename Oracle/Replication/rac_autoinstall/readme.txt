ReadME
# ============================================================
#  Oracle 19c RAC Auto Install Script
#  OS   : OEL 7.9
#  User : oracle / dba , grid / dba
#  Cluster Config : STANDALONE  
#
#  /storage/downloads file check & need dir
#  mkdir -p /storage/downloads
#  chmod -R 777 /storage
#  Script 경로 및 파일 위치 하드코딩 되어 있으므로 반드시 해당 경로에서 실행
#  19cgrid, 19cengine zip
#  GRID - 19c_grid_linux.zip
#  ORACLE - 19c_db_linux.zip
# 
#  랩 환경이기에 편의상 그룹셋팅은 전부 다 dba 그룹임. 
#
#  rac2_manual_task.sh 실행전 공유 디스크 & 네트워크 & 호스트네임 셋팅 필수
#  Root Disk 확인필수 및 확인 후 스크립트 내 ROOT_DISK 변수 수정
#
#  두번째 노드 머신부터는 첫번째 머신으로부터 복제해서 진행
#
#  해당 스크립트에서 oracle계정은 os 설치하면서 생성했다고 가정
#  
#  DNS 서버는 사용X 1개의 스캔리스너만 사용
#
#  host들 미리 셋팅(ip, name, shared disk)해놓으면 스크립트 끊기지않고 한번에 돌리기 가능할듯 (1,2번 스크립트 수정필요)
#
#
# ============================================================

# 권장셋팅
 ASMDISK01 -> +FRA
 ASMDISK0n -> +DATA
 -> 공유 스토리지 용량은 알아서 지정

 rac3_grid.sh에서 ASMDISK01을 FRA로 사용하도록 셋팅되어있음
 grid설치시 +DATA로 기본 셋팅 / rsp 파일 확인 후 disk 몇개 사용할지 수정 필요

Instance생성은 DBCA로 archive mode 기본으로 설정 및 아카이브 모드 경로는 +FRA로 지정되어있음.

chmod +x /storage/downloads/*.sh
chown -R root:root /storage/downloads/*.sh

# File List
 - ReadME.txt
 - Common.sh       --> 여기에 공용변수&함수 셋팅해야할값 몰아서 넣자
 - rac1_config.sh
 - rac2_manual_task.sh
 - rac3_grid.sh
 - rac4_oracle.sh
 - rac5_dbca.sh
 - hostlist
 - hosts(/etc/hosts)
 - db.rsp 
 - grid.rsp
 - dbca.rsp
 - sshUserSetup.sh
 
  HostList.txt 
  ex)
  racNode1
  racNode2
  racNode3
  ..
  .. 
 
# Task Sequence
 0. HostList & Hosts Setting
 1. Create Machine
 2. Run rac1_config.sh 
 3. Clone Machine / Network&Hostname Setting / Shared Storage Setting
 4. Run rac2_asm.sh -> Must Check Root_Disk / Default value is sda in script
 5. Run rac3_grid.sh
 6. Run rac4_oracle.sh
 7. Run rac5_dbca.sh
 
* 스크립트 돌리기전에 rsp파일과 Hostlist,hosts 파일을 구성할 환경에 맞게 수정필요 
 
# Directory
  GRID
	ORACLE_BASE=/u01/app/grid			-> GRID_BASE
	ORACLE_HOME=/u01/app/19.3.0/grid	-> GRID_HOME

 ORACLE
	ORACLE_BASE=/u02/app/oracle
 	ORACLE_HOME=/u02/app/oracle/product/19.3.0/dbhome_1

DATA DIR
	Using ASM / Default values is +DATA
			
FRA DIR
	Using ASM / Default values is +FRA // rac3_grid3.sh : line 132

oraInventory
 	/u01/app/oraInventory 











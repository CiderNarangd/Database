#!/bin/bash

# Global variables

GRID_ZIP=/storage/downloads/19c_grid_linux.zip
ORACLE_ZIP=/storage/downloads/19c_db_linux.zip
SSH_SCRIPT=/storage/downloads/sshUserSetup.sh


ORA_INVEN=/u01/app/oraInventory
GRID_HOME=/u01/app/19.3.0/grid
GRID_BASE=/u01/app/grid

ORACLE_BASE=/u02/app/oracle
ORACLE_HOME=/u02/app/oracle/product/19.3.0/dbhome_1


GRID_RSP=/storage/downloads/grid.rsp
DBCA_RSP=/storage/downloads/dbca.rsp
DB_RSP=/storage/downloads/db.rsp

HOSTS_FILE=/storage/downloads/hosts
HOSTS_LIST=/storage/downloads/hostlist

log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; echo "" | tee -a "$LOG"; }
die()  { echo "" | tee -a "$LOG"; echo "[ERROR] $*" | tee -a "$LOG"; exit 1; }
newline() { echo "" | tee -a "$LOG"; }

run_as_oracle() { 
	su - oracle -c "$1" 2>&1 | tee -a "$LOG";
	}
	
run_as_grid() { 
	su - grid -c "$1" 2>&1 | tee -a "$LOG";
	}
 


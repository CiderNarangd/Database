#-- coding: utf-8 --
from datetime import datetime, timedelta
import os.path
from os import path
import subprocess
import sys
######################################################
### 풀백업시간을 피해서 백업
### 따로 슬레이브로 전송하지는 않는다.
### 풀백업이후 하루 두번 진행
### 크론탭을 통해 관리, 실행시 인자값을 통해 풀백업이후 몇번째 증분백업인지 체크
### crontab -e
### ex) 0 8 * * *  incremental_backup.py 1
###     0 16 * * *  incremental_backup.py 2
#########################################################
increment_index = sys.argv[1]

backup_user = 'kinam'
back_host = 'asdf'

backup_date = datetime.now()
delete_date = backup_date - timedelta(days = 3)

backup_date_str = backup_date.strftime("%Y%m%d")
delete_date_str = delete_date.strftime("%Y%m%d")

inc_backup_date_str = "inc"+increment_index+ "_"  + backup_date_str 
inc_delete_date_str = "inc"+increment_index+ "_"  + delete_date_str 


basedir = f"/db/mysqlbackup/"
target_dir = f"/db/mysqlbackup/"
mycnf = f"/etc/my.cnf"


##delete old backup..
if(path.exists(f"{basedir}{inc_delete_date_str}")== True):
    cmd = f"sudo rm -r {basedir}{inc_delete_date_str}"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()


inc_backup_command = f"sudo xtrabackup --defaults-file={mycnf} --user=xtrabackup --password='12345' --target-dir=/db/mysqlbackup/{inc_backup_date_str} --incremental-basedir=/db/mysqlbackup/{backup_date_str} --backup --no-lock"
apply_inc_backup_command = f"sudo xtrabackup --prepare --apply-log-only --target-dir=/db/mysqlbackup/{backup_date_str} --incremental-dir=/db/mysqlbackup/{inc_backup_date_str}"

change_group_permission_cmd = f"sudo chown -R mysql:mysql {basedir}{inc_backup_date_str}"
permission_change_cmd = f"sudo chmod -R 777 {basedir}{inc_backup_date_str}"

apply_final_backup_cmd = f"sudo xtrabackup --prepare --target-dir=/db/mysqlbackup/{backup_date_str}"

##Incremental Backup
process = subprocess.Popen(inc_backup_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##Change permission

process = subprocess.Popen(change_group_permission_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

process = subprocess.Popen(permission_change_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##apply inc backup to full backup
process = subprocess.Popen(apply_inc_backup_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##Final backup apply
process = subprocess.Popen(apply_final_backup_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()
#-- coding: utf-8 --
from datetime import datetime, timedelta
import os.path
from os import path
import subprocess
###########################################
## Mysql_Master 서버에서 사용
## crontab 등록해서 사용.
## 크론탭 시간은 사용량 제일 적을때 or 백업실패서 대처가장 쉬운 시간에 사용
## 
## 
###################################

#슬레이브서버, 백업서버로 전송.

##define
slave_user = 'root'
slave_host = '211.184.32.82'

backup_host = '221.163.171.138'

backup_user = 'kinam'

backup_date = datetime.now()
delete_date = backup_date - timedelta(days = 3)

backup_date_str = backup_date.strftime("%Y%m%d")
delete_date_str = delete_date.strftime("%Y%m%d")

basedir = f"/db/mysqlbackup/"
target_dir = f"/db/mysqlbackup/"
mycnf = f"/etc/my.cnf"



##delete old backup..
if(path.exists(f"{basedir}{delete_date_str}")== True):
    cmd = f"sudo rm -r {basedir}{delete_date_str}"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()

full_backup_command = f"sudo xtrabackup --defaults-file={mycnf} --user=xtrabackup --password='12345' --target-dir=/db/mysqlbackup/{backup_date_str} --backup --no-lock"
apply_log_command = f"sudo xtrabackup --prepare --target-dir={target_dir}{backup_date_str}"

change_group_permission_cmd = f"sudo chown -R mysql:mysql {basedir}{backup_date_str}"
permission_change_cmd = f"sudo chmod -R 777 {target_dir}{backup_date_str}"

print(full_backup_command)
print(apply_log_command)

##full backup
process = subprocess.Popen(full_backup_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##appl redo log..
process = subprocess.Popen(apply_log_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##change dir permission 권한변경해야 전송돼서..
process = subprocess.Popen(change_group_permission_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

process = subprocess.Popen(permission_change_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##send slave..
send_slave_cmd = f'sudo scp -r {basedir}{backup_date_str} {slave_user}@{slave_host}:{basedir}'

process = subprocess.Popen(send_slave_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##send backup db server..
send_backup_cmd = f'sudo scp -r {basedir}{backup_date_str} {slave_user}@{backup_host}:{basedir}'

process = subprocess.Popen(send_backup_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

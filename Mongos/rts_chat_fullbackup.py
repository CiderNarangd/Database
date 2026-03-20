#-- coding: utf-8 --
import datetime
from datetime import datetime, timedelta
from os import path
import subprocess

## boto3 설치 필요
## 필요시 로그 기능 추가
## 

host = 'localhost'
port = 50020
backup_user = 'backup'
backup_user_pw = "pw"

#config_dir = '/etc/mongod.conf'
base_dir = '/mongo_backup/'
keep_period = 3

backup_date = datetime.now()
delete_date = backup_date - timedelta(keep_period)

backup_date_str = backup_date.strftime("%Y%m%d")
delete_date_str = delete_date.strftime("%Y%m%d")

##cmds
fullbackup_cmd = f'/storage/mengine/mongodump -u {backup_user} -p {backup_user_pw} --out {base_dir}{backup_date_str} --host {host} --port {port}'
mkdir_cmd = f'mkdir -p {base_dir}{backup_date_str}'

##delete old backup
if(path.exists(f"{base_dir}{delete_date_str}")== True):
    cmd = f"rm -rf {base_dir}{delete_date_str}"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()

##create new backup dir
process = subprocess.Popen(mkdir_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##full backup
process = subprocess.Popen(fullbackup_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
stdout, stderr = process.communicate()

##예외처리

## Send To S3
## 버킷명, 
## 압축추가.
exit()
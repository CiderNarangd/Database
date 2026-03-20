#-- coding: utf-8 --
import datetime
from datetime import datetime, timedelta
from os import path
import subprocess
import boto3


class s3:
    def __init__(self):
        #self.access_key = ''
        #self.secret_access = ''
        self.bucket = 'bucketname'
        self.region = 'ap-northeast-2'
        self.bucket_dir = 'bucket dir'
        
        self.s3_client = boto3.client(
             's3',
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_access,
            region_name=self.region
        )
        
    def file_upload(self,source,date_str):
        try:
            self.s3_client.upload_file(source, self.bucket,f'{self.bucket_dir}{date_str}/{date_str}.tar.gz')
        except Exception as e:
            print(f"An error occurred: {e}")

if __name__ == "__main__":
    
    ##craete s3 connect instance
    S3Instance = s3()
 
    ##backup init date     
    host = 'localhost'
    port = 50020
    backup_user = 'backup'
    backup_user_pw = ""

    #config_dir = '/etc/mongod.conf'
    base_dir = '/mongo_backup/'
    keep_period = 3
    
    backup_date = datetime.now()
    delete_date = backup_date - timedelta(keep_period)
    
    backup_date_str = backup_date.strftime("%Y%m%d")
    delete_date_str = delete_date.strftime("%Y%m%d")
    
    ##backup cmd
    fullbackup_cmd = f'/storage/mengine/mongodump -u {backup_user} -p {backup_user_pw} --out {base_dir}{backup_date_str} --host {host} --port {port}'
    mkdir_cmd = f'mkdir -p {base_dir}{backup_date_str}'

    compress_cmd = f'tar -zcvf {base_dir}{backup_date_str}.tar.gz {base_dir}{backup_date_str}'
    
    ##create new backup dir
    process = subprocess.Popen(mkdir_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()

    ##full backup
    process = subprocess.Popen(fullbackup_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()

    ##full backup compress
    process = subprocess.Popen(compress_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()
     
    ##delete old backup
    if(path.exists(f"{base_dir}{delete_date_str}")== True):
        cmd = f"rm -rf {base_dir}{delete_date_str}"
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        stdout, stderr = process.communicate()
 
    ##upload compress backup to s3
    S3Instance.file_upload(f'{base_dir}{backup_date_str}.tar.gz',backup_date_str)
    
    ##after s3 upload delete compress file..
    if(path.exists(f"{base_dir}{backup_date_str}.tar.gz")== True):
        del_comp_cmd = f'rm -rf {base_dir}{backup_date_str}.tar.gz'
        process = subprocess.Popen(del_comp_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        stdout, stderr = process.communicate()
    
    exit()
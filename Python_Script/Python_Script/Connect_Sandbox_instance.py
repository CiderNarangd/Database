#-- coding: utf-8 --
################################
# DB Deployer 설치된 Backup 서버에서 
# DB Deployer로 배포된 인스턴스들에 맞게끔 추가해서 사용
# 
################################
import os
import sys
os.system("clear")
print("==============================================")
print("Select Sandbox Host....")
print("1. Mysql- Master  --port = 3307")
print("2. Mysql- Master  --port = 3308")
print("==============================================")

print("Select Host : ",end="")
input_num = int(input())

if(input_num == 1) :
    os.system("~/opt/mysql/8.0.36/bin/mysql -u root -p --host=127.0.0.1 --port=3307")
elif(input_num == 2) :
    os.system("~/opt/mysql/8.0.36/bin/mysql -u root -p --host=127.0.0.1 --port=3308")
else:
    print("enter the correct number")

sys.exit()
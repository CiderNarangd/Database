#-- coding: utf-8 --
import os
import sys
import subprocess
import paramiko
import mysql.connector
import logging
from mysql.connector import Error

#호스트 리스트는 어디서 읽어올까..
#DB로 관리하자
#일단 가라로 하드코딩
#로그 기록하는 기능 추가.

#define
STATUS_CHK = 1
DB_START = 2
DB_STOP = 3
RPL_CHK = 4
RPL_START = 5
RPL_STOP = 6

EXIT = 99

status_cmd = 'systemctl status mysqld'
start_cmd  = 'systemctl start mysqld'
stop_cmd   = 'systemctl stop mysqld'

#querys

class mysqlConnector :
    connections = None
    def __init__(self):

        self.connections = mysql.connector.connect(
                host='211.184.32.98',   #Manager서버 호스트
                user='kinam',
                password='rlska123!@#',
                database = 'hosts'
            )
        if(self.connections.is_connected()):
            print("Mysql Connectte.d....")
        else:
            print("Mysql Connection fail exit program..")
            exit()

    def getConnection(self):
        return self.connections

    def CloseConnection(self):
        self.connections.close()

   
def status_chk(cmd):
    fd_popen = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    stdout, stderr = fd_popen.communicate()
    stderr = stderr.decode('utf-8')
    stdout = stdout.decode('utf-8')
    
    if(stderr):
        print(f"error : {stderr}")
    else:
        start_idx = stdout.find("Active") 
        end_idx = stdout.find("\n",start_idx)
        print(stdout[start_idx:end_idx])
        
    fd_popen.terminate()


def mysql_status_chk(connection:mysqlConnector):
    print("Mysql Status Chk...")
    cursor = connection.getConnection().cursor()
    query = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1;"
    cursor.execute(query)
    result = cursor.fetchall()

    #[0] hostanme [1] host_ip [2] service_status [3] is_master
    for row in result:

        print("==============================================")
        print(f"host_name {row[0]}")
        cmd = 'ssh root@' + row[1] + ' ' + status_cmd
        print(cmd)
        #status_chk(cmd_2)
        print("================================================")

    cursor.close()

    
def mysql_start(connection:mysqlConnector):
    print("Mysql Start...")
    cursor = connection.getConnection().cursor()
    query = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1;"
    cursor.execute(query)
    result = cursor.fetchall()

    #[0] hostanme [1] host_ip [2] service_status [3] is_master
    for row in result:

        print("==============================================")
        print(f"host_name {row[0]}")
        cmd = 'ssh root@' + row[1] + ' ' + start_cmd
        chk_cmd = 'ssh root@' + row[1] + ' ' + status_cmd

        print(cmd)
        print(chk_cmd)

        fd_popen = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = fd_popen.communicate()
        stderr = stderr.decode('utf-8')
        stdout = stdout.decode('utf-8')
        
        if(stderr):
            print(f"error : {stderr}")
        else:
            print("start successssss")
            status_chk(chk_cmd)
            
        fd_popen.terminate()

        print("================================================")

    exit()

def mysql_stop(connection:mysqlConnector):
    print("Mysql Stop...")
    cursor = connection.getConnection().cursor()
    query = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1;"
    cursor.execute(query)
    result = cursor.fetchall()

    #[0] hostanme [1] host_ip [2] service_status [3] is_master
    for row in result:

        print("==============================================")
        print(f"host_name {row[0]}")
        cmd = 'ssh root@' + row[1] + ' ' + stop_cmd
        chk_cmd = 'ssh root@' + row[1] + ' ' + status_cmd

        print(cmd)
        print(chk_cmd)

        fd_popen = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = fd_popen.communicate()
        stderr = stderr.decode('utf-8')
        stdout = stdout.decode('utf-8')
        
        if(stderr):
            print(f"error : {stderr}")
        else:
            print("stop successssss")
            status_chk(chk_cmd)
            
        fd_popen.terminate()

        print("================================================")

    exit()


def mysql_repl_chk(connector:mysqlConnector):
    try:
        print("Mysql Replication Check.")
        cursor = connector.getConnection().cursor()
        query = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1 and is_master = 0;"
        cursor.execute(query)
        result = cursor.fetchall()

        #[0] hostanme [1] host_ip [2] service_status [3] is_master
        for row in result:
            connection = mysql.connector.connect(
                host=row[1],
                user='kinam',
                password='rlska123!@#'
            )
            if connection.is_connected():   
                cursor = connection.cursor(dictionary=True)
                cursor.execute("SHOW SLAVE STATUS")
                result = cursor.fetchone()
                if result:
                    if result['Slave_IO_Running'] == 'Yes' and result['Slave_SQL_Running'] == 'Yes':
                        print("Replication is running properly.")
                    else:
                        print("Replication is not running properly. Please check the status:")
                        for key, value in result.items():
                            print(f"{key}: {value}")
                else:
                    print("No replication status found.")
                cursor.close()
                connection.close()
    except Error as e:
        print(f"Error connecting to MySQL: {e}")

    exit()

def mysql_repl_start(connector:mysqlConnector):
    try:
        print("Mysql Replication Start.")
        cursor = connector.getConnection().cursor()
        query = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1 and is_master = 0;"
        cursor.execute(query)
        result = cursor.fetchall()

        #[0] hostanme [1] host_ip [2] service_status [3] is_master
        for row in result:
            connection = mysql.connector.connect(
                host=row[1],
                user='kinam',
                password='rlska123!@#'
            )
            if connection.is_connected():   
                cursor = connection.cursor(dictionary=True)
                print(f"{row[0]} Start slave...")
                cursor.execute("START SLAVE;")
                result = cursor.fetchone()
                cursor.close()
                connection.close()
    except Error as e:
        print(f"Error connecting to MySQL: {e}")

def mysql_repl_stop(connector:mysqlConnector):
    try:
        print("Mysql Replication Start.")
        cursor = connector.getConnection().cursor()
        query = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1 and is_master = 0;"
        cursor.execute(query)
        result = cursor.fetchall()

        #[0] hostanme [1] host_ip [2] service_status [3] is_master
        for row in result:
            connection = mysql.connector.connect(
                host=row[1],
                user='kinam',
                password='rlska123!@#'
            )
            if connection.is_connected():   
                cursor = connection.cursor(dictionary=True)
                print(f"{row[0]} Stop slave...")
                cursor.execute("STOP SLAVE;")
                result = cursor.fetchone()
                cursor.close()
                connection.close()
    except Error as e:
        print(f"Error connecting to MySQL: {e}")


def main():
    print("Mysql Manager..")
    connector = mysqlConnector()

    print("1. Mysql status check")
    print("2. Mysql Server Start")
    print("3. Mysql Server Stop")
    print("4. Mysql Replication status")
    print("5. Mysql Replication start")
    print("6. Mysql Replication stop")
    print("99. EXIT")

    print(">> ", end='')
    input_num = int(input())

    if(input_num == STATUS_CHK) :
        mysql_status_chk(connector)
       
    elif(input_num == DB_START):
        mysql_start(connector)
    
    elif(input_num == DB_STOP):
        mysql_stop(connector)
    
    elif(input_num == RPL_CHK):
        mysql_repl_chk(connector)

    elif(input_num == RPL_START):
        mysql_repl_start(connector)

    elif(input_num == RPL_STOP):
        mysql_repl_stop(connector)

    elif(input_num == EXIT):
        connector.CloseConnection()

    connector.CloseConnection()


if __name__ == "__main__":
    main()
  
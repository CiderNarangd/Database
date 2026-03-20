#-- coding: utf-8 --
import subprocess
import mysql.connector
import logging
from mysql.connector import Error
from datetime import datetime


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
select_all_hosts = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1;"
select_slave_hosts = "select hostname, host_ip, service_status, is_master from HostList where service_status = 1 and is_master = 0;"

start_time = datetime.now().strftime("%Y%m%dT%H%M%S")
log_file_name = "./mysql_manager_logs/mysql_manager_log"+' '+ start_time + ".txt"

logging.basicConfig(filename=log_file_name, level=logging.INFO, 
                    format="[ %(asctime)s] %(message)s", 
                    datefmt="%Y-%m-%d %H:%M:%S")

logger = logging.getLogger()
logger.setLevel(logging.INFO)

stream_hander = logging.StreamHandler()
logger.addHandler(stream_hander)


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
            logger.info("Manager Server Mysql Connected...")
        else:
            logger.info("Mysql Connection fail.. exit program..")
            exit()

    def getConnection(self):
        return self.connections

    def CloseConnection(self):
        self.connections.close()

   
def status_chk(cmd):
    logger.info(f"use command : {cmd}")
    fd_popen = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    stdout, stderr = fd_popen.communicate()
    stderr = stderr.decode('utf-8')
    stdout = stdout.decode('utf-8')
    
    if(stderr):
        logger.info(f"error : {stderr}")
    else:
        start_idx = stdout.find("Active") 
        end_idx = stdout.find("\n",start_idx)
        logger.info(stdout[start_idx:end_idx])
        
    fd_popen.terminate()


def mysql_status_chk(connection:mysqlConnector):
    logger.info("Check Mysql Status...")
    cursor = connection.getConnection().cursor()
    cursor.execute(select_all_hosts)
    result = cursor.fetchall()

    #[0] hostanme [1] host_ip [2] service_status [3] is_master
    for row in result:
        logger.info("==============================================")
        logger.info(f"host_name {row[0]}")
        cmd = 'ssh root@' + row[1] + ' ' + status_cmd
        status_chk(cmd)
        logger.info("================================================")

    cursor.close()

    
def mysql_start(connection:mysqlConnector):
    logger.info("Mysql Start...")
    cursor = connection.getConnection().cursor()
    cursor.execute(select_all_hosts)
    result = cursor.fetchall()

    #[0] hostanme [1] host_ip [2] service_status [3] is_master
    for row in result:

        logger.info("==============================================")
        logger.info(f"target host : {row[0]}")
        cmd = 'ssh root@' + row[1] + ' ' + start_cmd
        chk_cmd = 'ssh root@' + row[1] + ' ' + status_cmd
        logger.info(f"use command : {cmd}")

        fd_popen = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = fd_popen.communicate()
        stderr = stderr.decode('utf-8')
        stdout = stdout.decode('utf-8')
        
        if(stderr):
            logger.info(f"error : {stderr}")
        else:
            logger.info("start successssss")
            status_chk(chk_cmd)
            
        fd_popen.terminate()
        
        logger.info("================================================")

    exit()

def mysql_stop(connection:mysqlConnector):
    logger.info("Mysql Stop...")
    cursor = connection.getConnection().cursor()
    cursor.execute(select_all_hosts)
    result = cursor.fetchall()

    #[0] hostanme [1] host_ip [2] service_status [3] is_master
    for row in result:

        logger.info("==============================================")
        logger.info(f"target host : {row[0]}")
        cmd = 'ssh root@' + row[1] + ' ' + stop_cmd
        chk_cmd = 'ssh root@' + row[1] + ' ' + status_cmd
        logger.info(f"use command : {cmd}")

        fd_popen = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = fd_popen.communicate()
        stderr = stderr.decode('utf-8')
        stdout = stdout.decode('utf-8')
        
        if(stderr):
            logger.info(f"error : {stderr}")
        else:
            logger.info("stop successssss")
            status_chk(chk_cmd)
            
        fd_popen.terminate()

        logger.info("================================================")

    exit()


def mysql_repl_chk(connector:mysqlConnector):
    try:
        logger.info("Check Mysql Replication...")
        cursor = connector.getConnection().cursor()
        cursor.execute(select_slave_hosts)
        result = cursor.fetchall()

        #[0] hostanme [1] host_ip [2] service_status [3] is_master
        for row in result:
            logger.info("==============================================")
            logger.info(f"target host : {row[0]}")
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
                        logger.info("Replication is running properly.")
                    else:
                        logger.info("Replication is not running properly. Please check the status:")
                        for key, value in result.items():
                            logger.info(f"{key}: {value}")
                else:
                    logger.info("No replication status found.")
                cursor.close()
                connection.close()
            logger.info("==============================================")
    except Error as e:
        logger.info(f"Error connecting to MySQL: {e}")

    exit()

def mysql_repl_start(connector:mysqlConnector):
    try:
        logger.info("Start Mysql Replication...")
        cursor = connector.getConnection().cursor()
        cursor.execute(select_slave_hosts)
        result = cursor.fetchall()

        #[0] hostanme [1] host_ip [2] service_status [3] is_master
        for row in result:
            logger.info("==============================================")
            logger.info(f"target host : {row[0]}")
            connection = mysql.connector.connect(
                host=row[1],
                user='kinam',
                password='rlska123!@#'
            )
            if connection.is_connected():   
                cursor = connection.cursor(dictionary=True)
                logger.info(f"{row[0]} Start slave...")
                cursor.execute("START SLAVE;")
                result = cursor.fetchone()
                cursor.close()
                connection.close()
    except Error as e:
        logger.info(f"Error connecting to MySQL: {e}")

def mysql_repl_stop(connector:mysqlConnector):
    try:
        logger.info("Stop Mysql Replication...")
        cursor = connector.getConnection().cursor()
        cursor.execute(select_slave_hosts)
        result = cursor.fetchall()

        #[0] hostanme [1] host_ip [2] service_status [3] is_master
        for row in result:
            logger.info("==============================================")
            logger.info(f"target host : {row[0]}")
            connection = mysql.connector.connect(
                host=row[1],
                user='kinam',
                password='rlska123!@#'
            )
            if connection.is_connected():   
                cursor = connection.cursor(dictionary=True)
                logger.info(f"{row[0]} Stop slave...")
                cursor.execute("STOP SLAVE;")
                result = cursor.fetchone()
                cursor.close()
                connection.close()
            logger.info("==============================================")
    except Error as e:
        logger.info(f"Error connecting to MySQL: {e}")


def main():
    logger.info("Mysql Manager..")
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
        print("Good Bye~")

    connector.CloseConnection()
    print("Good Bye~")

if __name__ == "__main__":
    main()
  
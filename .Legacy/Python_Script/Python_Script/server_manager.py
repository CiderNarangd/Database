#-- coding: utf-8 --
import mysql.connector
import logging
from datetime import datetime
import paramiko
import requests

### 크론탭 5분마다 작동
cpu_threshold = 80
mem_threshold = 80
disk_threshold = 80

bot_token = '7362568770:AAFeTcn-cSNAgZFtAj2E63NIrGCTAprWZTo'
chat_id = '-4286286792'

start_time = datetime.now().strftime("%Y%m%dT%H%M%S")
log_file_name = "./Server_threshold_notifer/Server_threshold_Notifer"+' '+ start_time + ".txt"

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
                host='211.51.77.68',   #Manager서버 호스트
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



def send_telegram(message):
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    data = {"chat_id": chat_id, "text": message}

    response = requests.post(url, data=data)
    if response.status_code == 200:
        logger.info("Message sent successfully")
    else:
        logger.info(f"Failed to send message: {response.status_code} - {response.text}")

def check_threshold(host_name,hostip,user_id,passwd):
    #인자값ㅈ추가
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostip, username=user_id, password=passwd)

        ##Check CPU
        stdin, stdout, stderr = client.exec_command("mpstat | tail -1 | awk '{print 100-$NF}'")
        cpu_usage = stdout.read().decode('utf-8').strip()
        if(float(cpu_usage) > float(cpu_threshold)) : 
            send_telegram(f"[{host_name}] CPU usage exceed threshold. current usage : {cpu_usage}")

        #check mem
        stdin, stdout, stderr = client.exec_command("free | grep Mem | awk '{print $3/$2 * 100.0}'")
        mem_usage = stdout.read().decode('utf-8').strip()
        if(float(mem_usage) > float(mem_threshold)) : 
            send_telegram(f"[{host_name}] MEMEMORY usage exceed threshold. current usage : {mem_usage}")
            
        #check disk
        stdin, stdout, stderr = client.exec_command("df / | tail -1 | awk '{print $5}'")
        disk_usage = stdout.read().decode('utf-8').strip()
        disk_usage = disk_usage.replace('%','')
        if(float(disk_usage) > float(disk_threshold)) : 
            send_telegram(f"[{host_name}] DISK usage exceed threshold. current usage : {disk_usage}")
        
        client.close()

    except Exception as e:
        logger.info(f"Error checking system status on {host_name}: {e}")
        send_telegram(f"Error checking system status on {host_name}: {e}")
        client.close()
        return

 

def main():
    connector = mysqlConnector()
    cursor = connector.getConnection().cursor()
    cursor.execute("select hostname, host_ip, service_status from HostList where service_status = 1; ")
    result = cursor.fetchall()

    #### user_id, passwd 하드코딩 되어있음 해당 컬럼 추가해서 호스트 리스트파일을 만들어서 관리하거나 데이터베이스에 컬럼추가
    #### 해서 관리. 각 서버들에 임계점 설정도 따로 할수 있는게 좋을듯하다.  

    for host in result:
        #[0] hostname, [1]host ip 
        hostname = host[0]
        host_ip = host[1]
        user_id = "kinam"       
        passwd = "rlska123!@#"
        check_threshold(hostname,host_ip,user_id,passwd) 
        #check_threshold(hostname,'211.51.77.68',user_id,passwd) test용

    connector.CloseConnection()


if __name__ == "__main__":
    main()
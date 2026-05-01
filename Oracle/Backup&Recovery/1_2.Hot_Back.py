import os
import shutil
import subprocess
from datetime import datetime

ORACLE_HOME = "/u01/app/oracle/product/19.3.0/dbhome_1" 
ORACLE_SID = "ORCL"
SOURCE_DIR = "/u02/oradata/ORCL"
BACKUP_BASE_DIR = "/home/oracle/backup/hot"
TIMESTAMP = datetime.now().strftime("%Y%m%d_%H%M%S")
TARGET_DIR = os.path.join(BACKUP_BASE_DIR, TIMESTAMP)


os.environ["ORACLE_HOME"] = ORACLE_HOME
os.environ["ORACLE_SID"] = ORACLE_SID
os.environ["PATH"] = f"{ORACLE_HOME}/bin:" + os.environ.get("PATH", "")

def run_sqlplus(command):
    """SQL*Plus Command"""
    process = subprocess.Popen(
        ['sqlplus', '-s', '/', 'as', 'sysdba'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    stdout, stderr = process.communicate(input=command)
    return stdout, stderr

def do_hot_backup():
   
    if not os.path.exists(TARGET_DIR):
        os.makedirs(TARGET_DIR)

    print(f"Start Hot Backup: {TIMESTAMP}")

    print("Alter Database Begin Backup...")
    stdout, _ = run_sqlplus("alter database begin backup;\nexit;")
    if "Database altered" in stdout:
        print("Success: Database is in backup mode.")
    else:
        print(f"Failed: {stdout}")
        return

    try:
        print(f"Copy Files: {SOURCE_DIR} -> {TARGET_DIR}")
        for item in os.listdir(SOURCE_DIR):
            s = os.path.join(SOURCE_DIR, item)
            d = os.path.join(TARGET_DIR, item)
            if os.path.isdir(s):
                shutil.copytree(s, d, dirs_exist_ok=True)
            else:
                shutil.copy2(s, d)
        print("Complete Copy!")

    except Exception as e:
        print(f"Error: {e}")

    finally:
        print("Alter Database End Backup...")
        stdout, _ = run_sqlplus("alter database end backup;\nalter system archive log current;\nexit;")
        if "Database altered" in stdout:
            print("Success: Database is out of backup mode.")
            print("Archive Current Log...")
        else:
            print(f"Failed: {stdout}")

    print(f"End Hot Backup: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    do_hot_backup()
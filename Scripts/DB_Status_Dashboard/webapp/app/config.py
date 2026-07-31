import os

from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DASHBOARD_DB_HOST", "localhost")
# 로컬 MySQL이 비표준 경로에 소켓을 두고 있어(/etc/my.cnf 참고), TCP(::1/127.0.0.1)로는
# 'localhost' 계정 권한이 매칭되지 않는다. 소켓 경로를 지정하면 mysql-connector-python이
# TCP 대신 유닉스 소켓으로 접속한다.
DB_SOCKET = os.getenv("DASHBOARD_DB_SOCKET", "/u01/mysql/manager/DATA/mysql.sock")
DB_USER = os.getenv("DASHBOARD_DB_USER", "dashboard_ro")
DB_PASSWORD = os.getenv("DASHBOARD_DB_PASSWORD", "oralce")
DB_NAME = os.getenv("DASHBOARD_DB_NAME", "lab_dashboard")

# 이 주기(분)의 2배보다 오래된 check_time은 화면에서 stale로 표시한다.
CHECK_INTERVAL_MINUTES = int(os.getenv("DASHBOARD_CHECK_INTERVAL_MINUTES", "5"))

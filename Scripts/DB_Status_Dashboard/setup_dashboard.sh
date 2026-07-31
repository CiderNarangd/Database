#!/usr/bin/env bash
#
# Lab DB 상태 대시보드 설치 스크립트 (Manager 호스트, 최초 1회 실행)
#
# 수행 작업:
#   1) lab_dashboard 스키마/계정 생성 (lab_dashboard_schema.sql)
#   2) webapp 파이썬 가상환경 생성 + 의존성 설치
#   3) check_mysql_status.sh 크론 등록 (5분 간격)
#   4) mysql-dashboard systemd 서비스 설치/기동 (sudo 필요)
#
# 실행: bash setup_dashboard.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBAPP_DIR="${SCRIPT_DIR}/webapp"

echo "[1/4] lab_dashboard 스키마 적용..."
mysql -uroot -poracle < "${SCRIPT_DIR}/lab_dashboard_schema.sql"
echo "  -> OK"

echo "[2/4] webapp 파이썬 가상환경 준비..."
cd "${WEBAPP_DIR}"
if [ ! -d .venv ]; then
  python3 -m venv .venv
fi
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -r requirements.txt
[ -f .env ] || cp .env.example .env
echo "  -> OK"

echo "[3/4] crontab 등록 (*/5 * * * * check_mysql_status.sh / check_oracle_status.sh)..."
mkdir -p "${SCRIPT_DIR}/logs"
MYSQL_CRON_LINE="*/5 * * * * ${SCRIPT_DIR}/check_mysql_status.sh >> ${SCRIPT_DIR}/logs/check_mysql_status.log 2>&1"
ORACLE_CRON_LINE="*/5 * * * * ${SCRIPT_DIR}/check_oracle_status.sh >> ${SCRIPT_DIR}/logs/check_oracle_status.log 2>&1"
( crontab -l 2>/dev/null | grep -v -e 'check_mysql_status.sh' -e 'check_oracle_status.sh' ; echo "${MYSQL_CRON_LINE}" ; echo "${ORACLE_CRON_LINE}" ) | crontab -
echo "  -> OK ($(crontab -l | grep -e check_mysql_status.sh -e check_oracle_status.sh | wc -l)건 등록)"

echo "[4/4] systemd 서비스 설치 (sudo 필요)..."
sudo cp "${WEBAPP_DIR}/mysql-dashboard.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now mysql-dashboard
echo "  -> OK ($(systemctl is-active mysql-dashboard))"

echo
echo "완료. http://$(hostname -I | awk '{print $1}'):8000 에서 대시보드 확인 가능."

from contextlib import contextmanager

import mysql.connector
from mysql.connector import pooling

from app import config

_pool = pooling.MySQLConnectionPool(
    pool_name="lab_dashboard_pool",
    pool_size=5,
    host=config.DB_HOST,
    unix_socket=config.DB_SOCKET,
    user=config.DB_USER,
    password=config.DB_PASSWORD,
    database=config.DB_NAME,
)


@contextmanager
def get_cursor():
    conn = _pool.get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        try:
            yield cursor
        finally:
            cursor.close()
    finally:
        conn.close()


def _fetch_hosts_with_latest_checks(query, extra_fields):
    with get_cursor() as cursor:
        cursor.execute(query)
        rows = cursor.fetchall()

    hosts = {}
    for row in rows:
        hostname = row["hostname"]
        host = hosts.setdefault(
            hostname,
            {
                "hostname": hostname,
                "host_ip": row["host_ip"],
                "cluster_type": row["cluster_type"],
                "role": row["role"],
                "checks": {},
                **{field: row[field] for field in extra_fields},
            },
        )
        if row["check_name"] is not None:
            host["checks"][row["check_name"]] = {
                "status": row["status"],
                "detail": row["detail"],
                "checked_at": row["checked_at"],
            }

    return list(hosts.values())


# 호스트별 체크 항목(check_name)별 최신 상태 1건.
# check_name 기반 구조라 새 점검 종류가 추가되어도 이 쿼리/헬퍼만 그대로 재사용된다.
_LATEST_MYSQL_CHECKS_QUERY = """
    SELECT h.hostname, h.host_ip, h.cluster_type, h.role, h.service_name,
           c.check_name, c.status, c.detail, c.checked_at
    FROM hosts h
    LEFT JOIN checks c
      ON c.hostname = h.hostname
      AND c.checked_at = (
        SELECT MAX(c2.checked_at) FROM checks c2
        WHERE c2.hostname = h.hostname AND c2.check_name = c.check_name
      )
    WHERE h.enabled = 1
    ORDER BY h.id
"""

_LATEST_ORACLE_CHECKS_QUERY = """
    SELECT h.hostname, h.host_ip, h.cluster_type, h.role, h.oracle_sid, h.db_unique_name,
           c.check_name, c.status, c.detail, c.checked_at
    FROM oracle_hosts h
    LEFT JOIN checks c
      ON c.hostname = h.hostname
      AND c.checked_at = (
        SELECT MAX(c2.checked_at) FROM checks c2
        WHERE c2.hostname = h.hostname AND c2.check_name = c.check_name
      )
    WHERE h.enabled = 1
    ORDER BY h.id
"""


def fetch_latest_mysql_status():
    return _fetch_hosts_with_latest_checks(_LATEST_MYSQL_CHECKS_QUERY, ["service_name"])


def fetch_latest_oracle_status():
    return _fetch_hosts_with_latest_checks(
        _LATEST_ORACLE_CHECKS_QUERY, ["oracle_sid", "db_unique_name"]
    )

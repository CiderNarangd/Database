from datetime import datetime

from app import config

STALE_AFTER_MINUTES = config.CHECK_INTERVAL_MINUTES * 2


def annotate_staleness(hosts):
    now = datetime.now()
    for host in hosts:
        for check in host["checks"].values():
            checked_at = check["checked_at"]
            check["is_stale"] = (
                checked_at is None
                or (now - checked_at).total_seconds() > STALE_AFTER_MINUTES * 60
            )
    return hosts

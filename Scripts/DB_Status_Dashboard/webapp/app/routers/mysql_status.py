from fastapi import APIRouter

from app import db
from app.staleness import annotate_staleness

router = APIRouter()


@router.get("/api/mysql/status")
def api_status():
    return {"hosts": annotate_staleness(db.fetch_latest_mysql_status())}

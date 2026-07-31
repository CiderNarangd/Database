from fastapi import APIRouter, Request

from app import db
from app.staleness import annotate_staleness
from app.templating import templates

router = APIRouter()


@router.get("/")
def index(request: Request):
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "mysql_hosts": annotate_staleness(db.fetch_latest_mysql_status()),
            "oracle_hosts": annotate_staleness(db.fetch_latest_oracle_status()),
        },
    )

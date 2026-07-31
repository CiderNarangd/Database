from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.routers import dashboard, mysql_status, oracle_status

app = FastAPI(title="DB Status Dashboard")

app.mount(
    "/static",
    StaticFiles(directory=str(Path(__file__).parent / "static")),
    name="static",
)

app.include_router(dashboard.router)
app.include_router(mysql_status.router)
app.include_router(oracle_status.router)

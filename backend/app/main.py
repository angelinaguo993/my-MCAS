from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect, text

from app.db.database import engine, Base
from app.api import episodes, insights

# Creates tables on startup if they don't exist yet
Base.metadata.create_all(bind=engine)

# create_all does not add columns to an existing SQLite/Postgres table.
existing_columns = {column["name"] for column in inspect(engine).get_columns("episodes")}
with engine.begin() as connection:
    if "end_date" not in existing_columns:
        connection.execute(text("ALTER TABLE episodes ADD COLUMN end_date TIMESTAMP"))
    if "weather_summary" not in existing_columns:
        connection.execute(text("ALTER TABLE episodes ADD COLUMN weather_summary VARCHAR"))

app = FastAPI(title="MCAS Tracker API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(episodes.router)
app.include_router(insights.router)


@app.get("/")
def root():
    return {"status": "ok"}

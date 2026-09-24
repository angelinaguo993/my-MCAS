from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db.database import engine, Base
from app.api import episodes, insights

# Creates tables on startup if they don't exist yet (fine for SQLite/dev;
# swap for a real migration tool like Alembic before this goes to production).
Base.metadata.create_all(bind=engine)

app = FastAPI(title="MCAS Tracker API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this before shipping publicly
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(episodes.router)
app.include_router(insights.router)


@app.get("/")
def root():
    return {"status": "ok"}

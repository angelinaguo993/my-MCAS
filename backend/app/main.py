from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db.database import engine, Base
from app.api import episodes, insights

# Creates tables on startup if they don't exist yet
Base.metadata.create_all(bind=engine)

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

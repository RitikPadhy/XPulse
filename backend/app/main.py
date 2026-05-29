from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, me, snapshot, system
from app.config import get_settings
from app.db import Base, SessionLocal, engine
from app import models  # noqa: F401  (register mappers before create_all)
from app.quests import seed_catalog


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    # Idempotently populate the quest catalog (metric × tier daily quests).
    with SessionLocal() as db:
        seed_catalog(db)
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="XPulse Backend", version="0.1.0", lifespan=lifespan)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(system.router)
    app.include_router(auth.router)
    app.include_router(me.router)
    app.include_router(snapshot.router)
    return app


app = create_app()

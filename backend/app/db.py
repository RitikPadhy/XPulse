import os

from sqlalchemy import URL, create_engine


def _build_url() -> URL:
    return URL.create(
        drivername="postgresql+psycopg",
        username=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        host=os.environ.get("PGHOST", "127.0.0.1"),
        port=int(os.environ.get("PGPORT", "5432")),
        database=os.environ["PGDATABASE"],
    )


engine = create_engine(_build_url(), pool_pre_ping=True)

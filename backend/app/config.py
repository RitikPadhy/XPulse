import os
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import URL


def _database_url_from_pg_env() -> str | None:
    required = ("PGUSER", "PGPASSWORD", "PGDATABASE")
    if not all(os.environ.get(k) for k in required):
        return None
    url = URL.create(
        drivername="postgresql+psycopg",
        username=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        host=os.environ.get("PGHOST", "127.0.0.1"),
        port=int(os.environ.get("PGPORT", "5432")),
        database=os.environ["PGDATABASE"],
    )
    return url.render_as_string(hide_password=False)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="XPULSE_",
        extra="ignore",
    )

    env: str = "dev"
    database_url: str = "sqlite:///./xpulse.db"
    cors_origins: str = "*"
    api_token: str = "dev-token-change-me"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    if settings.database_url == "sqlite:///./xpulse.db":
        pg_url = _database_url_from_pg_env()
        if pg_url:
            settings = settings.model_copy(update={"database_url": pg_url})
    return settings

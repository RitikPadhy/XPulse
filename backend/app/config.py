from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


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
    return Settings()

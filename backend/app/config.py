from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="XPULSE_", env_file=".env")

    env: str = "dev"
    database_url: str = "sqlite+aiosqlite:///./xpulse.db"
    cors_origins: str = "*"
    apple_client_id: str = ""

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


settings = Settings()

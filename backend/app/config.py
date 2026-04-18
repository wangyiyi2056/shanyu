from pydantic_settings import BaseSettings
from functools import lru_cache
from pathlib import Path


class Settings(BaseSettings):
    # Database - use absolute path
    database_url: str = ""

    # Google OAuth
    google_client_id: str = ""
    google_client_secret: str = ""

    # JWT
    jwt_secret: str = "dev-secret-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 24

    # App
    app_name: str = "Hiking Assistant API"
    debug: bool = True

    def get_database_url(self) -> str:
        """Get absolute database URL."""
        if not self.database_url:
            # Default: SQLite in backend/data directory
            backend_dir = Path(__file__).parent.parent
            data_dir = backend_dir / "data"
            data_dir.mkdir(parents=True, exist_ok=True)
            db_path = data_dir / "hiking.db"
            return f"sqlite:///{db_path}"
        return self.database_url

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
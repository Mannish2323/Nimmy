"""
🟣 NIMMY AI Brain — Configuration Settings
===========================================
"""

import os
from pydantic import BaseModel


class Settings(BaseModel):
    SERVICE_NAME: str = "nimmy-ai-brain"
    VERSION: str = "1.0.0"
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"

    # AI Model Provider
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    # Supabase / Vector DB
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

    # Security
    JWT_SECRET: str = os.getenv("JWT_SECRET", "nimmy-secret-key-change-in-production")


settings = Settings()

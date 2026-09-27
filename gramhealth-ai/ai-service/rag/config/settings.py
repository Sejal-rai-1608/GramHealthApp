import os
from typing import Optional
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    gemini_api_key: Optional[str] = None
    gemini_model: str = "gemini-3.5-flash-lite"
    vector_db_path: str = "./chroma_db"
    top_k: int = 30
    similarity_threshold: float = 1.25
    chunk_size: int = 1000
    chunk_overlap: int = 200
    max_context_tokens: int = 15000
    
    embedding_provider: str = "local"
    local_embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    chroma_collection: str = "gramhealth_medical_rag_local"
    
    class Config:
        env_file = ".env"

settings = Settings()

def get_gemini_api_key() -> Optional[str]:
    """
    Dynamically retrieves the configured Gemini API key from environment
    or Settings, prioritizing GEMINI_API_KEY over GOOGLE_API_KEY.
    Returns None if missing, empty, or whitespace-only.
    Never prints or logs the key value.
    """
    key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY") or settings.gemini_api_key
    if key and key.strip():
        return key.strip()
    return None

def is_gemini_configured() -> bool:
    """Returns True if a valid non-empty Gemini API key is configured."""
    return get_gemini_api_key() is not None

def require_gemini_api_key() -> str:
    """
    Returns the configured Gemini API key, or raises a clear configuration error
    if missing or empty. Never logs or prints the key.
    """
    key = get_gemini_api_key()
    if not key:
        raise ValueError(
            "Gemini API key is not configured. "
            "Please set the GEMINI_API_KEY or GOOGLE_API_KEY environment variable in your deployment environment or .env file."
        )
    return key

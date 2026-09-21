from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    gemini_api_key: str
    gemini_model: str = "gemini-3.6-flash"
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

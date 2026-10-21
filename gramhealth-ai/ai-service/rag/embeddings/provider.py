import logging
import time
from typing import List
from langchain_core.embeddings import Embeddings
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)

class GeminiEmbeddingProvider(Embeddings):
    """
    Abstracts the embedding provider, defaulting to Gemini.
    Implements batching and exponential backoff to respect free-tier quotas (100 RPM).
    """
    def __init__(self, api_key: str, batch_size: int = 100):
        self.underlying_embeddings = GoogleGenerativeAIEmbeddings(
            model="models/gemini-embedding-001",
            google_api_key=api_key
        )
        self.batch_size = batch_size

    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        total_chunks = len(texts)
        estimated_requests = (total_chunks + self.batch_size - 1) // self.batch_size
        logger.info(f"Embedding {total_chunks} chunks using Gemini.")
        logger.info(f"Configured batch size: {self.batch_size}.")
        logger.info(f"Estimated number of embedding API requests: {estimated_requests}")

        all_embeddings = []
        for i in range(0, total_chunks, self.batch_size):
            batch_texts = texts[i:i + self.batch_size]
            
            # Simple retry/backoff for HTTP 429
            max_retries = 3
            base_delay = 4.0
            
            for attempt in range(max_retries):
                try:
                    batch_embeddings = self.underlying_embeddings.embed_documents(batch_texts)
                    all_embeddings.extend(batch_embeddings)
                    break
                except Exception as e:
                    error_msg = str(e).lower()
                    if "429" in error_msg or "resource_exhausted" in error_msg or "quota" in error_msg:
                        if attempt < max_retries - 1:
                            sleep_time = base_delay * (2 ** attempt)
                            logger.warning(f"429 RESOURCE_EXHAUSTED hit. Backing off for {sleep_time} seconds before retry {attempt + 1}/{max_retries}...")
                            time.sleep(sleep_time)
                        else:
                            logger.error("Max retries exceeded for embedding batch.")
                            raise e
                    else:
                        raise e
            
            # Brief pause between successful batches if multiple batches are needed
            if estimated_requests > 1 and i + self.batch_size < total_chunks:
                time.sleep(1.0)
                
        return all_embeddings

    def embed_query(self, text: str) -> List[float]:
        return self.underlying_embeddings.embed_query(text)

class LocalEmbeddingProvider(Embeddings):
    """
    Local embedding provider using sentence-transformers.
    """
    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2"):
        logger.info(f"Loading local embedding model: {model_name}")
        self.model = SentenceTransformer(model_name)

    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        if not texts:
            return []
        embeddings = self.model.encode(texts)
        return embeddings.tolist()

    def embed_query(self, text: str) -> List[float]:
        if not text:
            return []
        embedding = self.model.encode(text)
        return embedding.tolist()

def get_embedding_provider(provider_type: str, model_name: str = None, api_key: str = None) -> Embeddings:
    if provider_type == "local":
        return LocalEmbeddingProvider(model_name=model_name or "sentence-transformers/all-MiniLM-L6-v2")
    elif provider_type == "gemini":
        return GeminiEmbeddingProvider(api_key=api_key, batch_size=100)
    else:
        raise ValueError(f"Unknown embedding provider: {provider_type}")

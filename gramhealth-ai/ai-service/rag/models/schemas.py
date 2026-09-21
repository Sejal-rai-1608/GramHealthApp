from pydantic import BaseModel, Field
from typing import List, Optional, Literal

class Citation(BaseModel):
    title: Optional[str] = None
    publisher: Optional[str] = None
    url: Optional[str] = None
    chunk_id: str

class RAGResponse(BaseModel):
    query: str
    answer: str
    grounded: bool
    confidence: Literal["high", "moderate", "low"]
    requires_professional_review: bool
    sources: List[Citation]

class RAGQueryRequest(BaseModel):
    query: str
    top_k: Optional[int] = None
    filters: Optional[dict] = None

class ChunkMetadata(BaseModel):
<<<<<<< HEAD
    document_id: str
=======
    document_id: Optional[str] = None
>>>>>>> f9f5067 (Initial commit)
    chunk_id: str
    title: Optional[str] = None
    source: Optional[str] = None
    source_url: Optional[str] = None
    publisher: Optional[str] = None
    publication_date: Optional[str] = None
    document_type: Optional[str] = None
    language: Optional[str] = None
<<<<<<< HEAD
=======
    patient_id: Optional[str] = None
    record_id: Optional[str] = None
    record_type: Optional[str] = None
    record_date: Optional[str] = None
    collection: Optional[str] = None
>>>>>>> f9f5067 (Initial commit)

class RetrievalResult(BaseModel):
    chunk_id: str
    score: float
    text: str
    metadata: ChunkMetadata

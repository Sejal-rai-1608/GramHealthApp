import logging
from typing import List, Optional, Dict, Any
from langchain_core.documents import Document
from rag.config.settings import settings
from rag.embeddings.provider import get_embedding_provider
from rag.retrieval.vector_store import ChromaVectorStore
from rag.retrieval.relevance import RelevanceFilter
from rag.models.schemas import Citation, ChunkMetadata
from .models import PatientContext, PatientRecordChunk

logger = logging.getLogger(__name__)

class PatientRAGService:
    def __init__(self):
        self.embeddings = get_embedding_provider(
            provider_type=settings.embedding_provider,
            model_name=settings.local_embedding_model,
            api_key=settings.gemini_api_key
        )
        self.vector_store = ChromaVectorStore(
            settings.vector_db_path, 
            self.embeddings,
            collection_name="patient_records"
        )
        self.relevance_filter = RelevanceFilter(settings.similarity_threshold)

    def insert_chunks(self, chunks: List[PatientRecordChunk]) -> List[str]:
        """
        Inserts structured patient record chunks into the vector store.
        """
        documents = []
        for c in chunks:
            doc = Document(
                page_content=c.text,
                metadata={
                    "chunk_id": c.chunk_id,
                    "patient_id": c.patient_id,
                    "record_id": c.record_id,
                    "record_type": c.record_type,
                    "record_date": c.record_date,
                    "source": c.source or "unknown",
                    "collection": "patient_records"
                }
            )
            documents.append(doc)
        return self.vector_store.insert_documents(documents)

    def query(self, query_text: str, patient_context: PatientContext, top_k: int = None) -> List[Dict[str, Any]]:
        """
        Retrieves relevant patient records, strictly bounded by the trusted patient_context.
        """
        if not patient_context or not getattr(patient_context, 'patient_id', None):
            logger.error("PatientRAGService query aborted: missing trusted patient_id")
            raise ValueError("A trusted patient identity is required to query patient records.")
            
        k = top_k or settings.top_k
        
        # Security Boundary: Enforce patient_id on the database query itself
        filters = {"patient_id": patient_context.patient_id}
        
        raw_results = self.vector_store.search_similarity(query_text, top_k=k, filters=filters)
        filtered_results = self.relevance_filter.filter_and_format(raw_results)
        
        evidence = []
        for res in filtered_results:
            evidence.append({
                "chunk_id": res.chunk_id,
                "text": res.text,
                "source_type": "patient_record",
                "patient_id": res.metadata.patient_id,
                "record_id": res.metadata.record_id,
                "record_type": res.metadata.record_type,
                "record_date": res.metadata.record_date,
                "source": res.metadata.source
            })
            
        return evidence

import logging
from typing import List, Optional
from langchain_core.documents import Document

from .config.settings import settings, is_gemini_configured
from .models.schemas import RAGResponse, Citation, RetrievalResult
from .ingestion.loader import ingest_pdf
from .chunking.splitter import chunk_documents
from .embeddings.provider import get_embedding_provider
from .retrieval.vector_store import ChromaVectorStore
from .retrieval.relevance import RelevanceFilter
from .generation.context_builder import ContextBuilder
from .generation.gemini import GeminiGenerator
from .generation.citations import CitationValidator

logger = logging.getLogger(__name__)

class RAGPipeline:
    def __init__(self):
        logger.info(f"Embedding provider: {settings.embedding_provider}")
        logger.info(f"Embedding model: {settings.local_embedding_model if settings.embedding_provider == 'local' else 'models/gemini-embedding-001'}")
        logger.info("Vector store: ChromaDB")
        logger.info(f"Collection: {settings.chroma_collection}")

        self.embeddings = get_embedding_provider(
            provider_type=settings.embedding_provider,
            model_name=settings.local_embedding_model,
            api_key=settings.gemini_api_key
        )
        self.vector_store = ChromaVectorStore(
            settings.vector_db_path, 
            self.embeddings,
            collection_name=settings.chroma_collection
        )
        self.relevance_filter = RelevanceFilter(settings.similarity_threshold)
        self.generator = GeminiGenerator(
            api_key=settings.gemini_api_key,
            model_name=settings.gemini_model
        )

    def ingest(
        self, 
        file_path: str, 
        source_url: Optional[str] = None, 
        publisher: Optional[str] = None,
        document_id: Optional[str] = None,
        publication_date: Optional[str] = None,
        content_hash: Optional[str] = None,
        source_type: str = "medical_knowledge"
    ) -> List[str]:
        # 1. Ingest
        documents = ingest_pdf(
            file_path, 
            source_url, 
            publisher,
            document_id=document_id,
            publication_date=publication_date,
            content_hash=content_hash,
            source_type=source_type
        )
        # 2. Chunk
        chunks = chunk_documents(documents, settings.chunk_size, settings.chunk_overlap)
        # 3. Store
        return self.vector_store.insert_documents(chunks)

    def retrieve(self, query_text: str, top_k: int = None) -> List[RetrievalResult]:
        """
        Independently testable retrieval method that queries the vector store
        and filters for relevance without triggering Gemini generation.
        """
        k = top_k or settings.top_k
        raw_results = self.vector_store.search_similarity(query_text, top_k=k)
        return self.relevance_filter.filter_and_format(raw_results)

    def query(self, query_text: str, top_k: int = None) -> RAGResponse:
        k = top_k or settings.top_k
        
        # 1. Retrieve
        filtered_results = self.retrieve(query_text, top_k=k)
        
        if not filtered_results:
            return RAGResponse(
                query=query_text,
                answer="Insufficient evidence was retrieved from the approved medical knowledge base to provide a grounded answer.",
                grounded=False,
                confidence="low",
                requires_professional_review=True,
                sources=[]
            )
            
        # 2. Build context
        context = ContextBuilder.build_context(filtered_results)
        
        # 3. Generate Answer
        raw_response = self.generator.generate(query_text, context)
        
        # 4. Validate citations
        if raw_response.referenced_chunk_ids:
            citations = CitationValidator.validate_and_build(raw_response.referenced_chunk_ids, filtered_results)
        elif not is_gemini_configured():
            citations = [
                Citation(
                    title=res.metadata.title,
                    publisher=res.metadata.publisher,
                    url=res.metadata.source_url,
                    chunk_id=res.metadata.chunk_id
                )
                for res in filtered_results
            ]
        else:
            citations = []
        
        return RAGResponse(
            query=query_text,
            answer=raw_response.answer,
            grounded=raw_response.grounded,
            confidence=raw_response.confidence,
            requires_professional_review=raw_response.requires_professional_review,
            sources=citations
        )

import logging
from typing import List, Tuple
from langchain_core.documents import Document
from ..models.schemas import RetrievalResult, ChunkMetadata

logger = logging.getLogger(__name__)

class RelevanceFilter:
    """
    Filters retrieved documents based on a similarity threshold.
    Note: Chroma uses L2 distance by default. Lower score = more similar.
    """
    def __init__(self, similarity_threshold: float):
        self.threshold = similarity_threshold

    def filter_and_format(self, results: List[Tuple[Document, float]]) -> List[RetrievalResult]:
        logger.info("=== RAW RETRIEVAL DIAGNOSTICS ===")
        logger.info(f"Number of raw Chroma results: {len(results)}")
        logger.info(f"Configured distance threshold: {self.threshold} (lower is better)")
        
        filtered_results = []
        for doc, score in results:
            chunk_id = doc.metadata.get('chunk_id')
            
            # Chroma L2 distance: lower score means it's a better match
            if score <= self.threshold:
                logger.info(f"KEPT chunk_{chunk_id} (distance {score:.4f} <= {self.threshold})")
                metadata = ChunkMetadata(**doc.metadata)
                filtered_results.append(
                    RetrievalResult(
                        chunk_id=metadata.chunk_id,
                        score=score,
                        text=doc.page_content,
                        metadata=metadata
                    )
                )
            else:
                logger.info(f"REJECTED chunk_{chunk_id} (distance {score:.4f} > {self.threshold})")
                
        logger.info(f"FILTER SUMMARY: Kept {len(filtered_results)} of {len(results)} chunks")
        logger.info("==================================")
        return filtered_results

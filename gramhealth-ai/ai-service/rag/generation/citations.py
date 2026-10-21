from typing import List, Dict
from ..models.schemas import RetrievalResult, Citation

class CitationValidator:
    """
    Server-side validation of chunk_ids referenced by the LLM.
    Ensures that citations match actual retrieved chunks and constructs
    citations from trusted server-side metadata, not model hallucinations.
    """
    @staticmethod
    def validate_and_build(referenced_chunk_ids: List[str], retrieved_results: List[RetrievalResult]) -> List[Citation]:
        # Map retrieved chunks by their valid chunk_id
        valid_chunks_map: Dict[str, RetrievalResult] = {
            res.chunk_id: res for res in retrieved_results
        }
        
        final_citations = []
        for ref_id in referenced_chunk_ids:
            if ref_id in valid_chunks_map:
                chunk = valid_chunks_map[ref_id]
                metadata = chunk.metadata
                final_citations.append(
                    Citation(
                        title=metadata.title,
                        publisher=metadata.publisher,
                        url=metadata.source_url,
                        chunk_id=metadata.chunk_id
                    )
                )
            else:
                # Log or ignore hallucinated reference
                pass
                
        # Optional: if model returns no valid references but we know we passed context, 
        # we might want to attach all passed context as citations as fallback,
        # but strict grounding requires only explicitly referenced ones.
        return final_citations

from typing import List
from ..models.schemas import RetrievalResult

class ContextBuilder:
    """
    Constructs the prompt context from retrieved chunks.
    """
    @staticmethod
    def build_context(results: List[RetrievalResult]) -> str:
        if not results:
            return ""
            
        context_parts = []
        for res in results:
            title = res.metadata.title or "Unknown Source"
            chunk_id = res.chunk_id
            text = res.text.strip()
            
            # Format explicitly separates evidence from instructions
            context_parts.append(
                f"--- START EVIDENCE ---\n"
                f"Source Title: {title}\n"
                f"Chunk ID: {chunk_id}\n"
                f"Content:\n{text}\n"
                f"--- END EVIDENCE ---"
            )
            
        return "\n\n".join(context_parts)

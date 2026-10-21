from pydantic import BaseModel, Field
from typing import List, Literal, Optional, Any
from rag.pipeline import RAGPipeline
from rag.generation.gemini import GeminiRawResponse
from rag.models.schemas import Citation

class RAGAgentResponse(BaseModel):
    response: str = Field(description="The generated answer from the knowledge base.")
    grounded: bool = Field(description="Whether the response is fully supported by the retrieved evidence.")
    confidence: Literal["low", "medium", "high"] = Field(description="Confidence in the response.")
    sources: List[Citation] = Field(description="List of Citations referenced.")
    requires_professional_review: bool = Field(default=True)

class RAGAgent:
    def __init__(self):
        # We can initialize RAGPipeline here or accept it as dependency. 
        # For prototype simplicity, initialize a new instance.
        self.pipeline = RAGPipeline()

    def execute(self, query: str) -> RAGAgentResponse:
        rag_response = self.pipeline.query(query)
        
        return RAGAgentResponse(
            response=rag_response.answer,
            grounded=rag_response.grounded,
            confidence=rag_response.confidence,
            sources=rag_response.sources,
            requires_professional_review=rag_response.requires_professional_review
        )

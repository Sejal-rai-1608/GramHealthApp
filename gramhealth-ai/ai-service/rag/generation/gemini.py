import logging
from typing import List, Optional
from pydantic import BaseModel, Field
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from ..models.schemas import RetrievalResult
from ..config.settings import get_gemini_api_key

logger = logging.getLogger(__name__)

# Model output schema (raw from Gemini)
class GeminiRawResponse(BaseModel):
    answer: str = Field(description="The grounded answer to the query based ONLY on the evidence.")
    grounded: bool = Field(description="True if the answer is grounded in the provided evidence.")
    confidence: str = Field(description="high, moderate, or low")
    requires_professional_review: bool = Field(description="True if the user should consult a medical professional.")
    referenced_chunk_ids: List[str] = Field(description="List of Chunk IDs explicitly used to formulate the answer.")

class GeminiGenerator:
    def __init__(self, api_key: Optional[str] = None, model_name: str = "gemini-3.5-flash-lite"):
        self.api_key = api_key
        self.model_name = model_name
        self._llm = None
        self._cached_api_key = None

        self.prompt = ChatPromptTemplate.from_messages([
            ("system", 
             "You are a Medical AI Assistant. Your role is clinical decision support, not autonomous diagnosis.\n"
             "You MUST ground your answers entirely in the provided RETRIEVED_MEDICAL_EVIDENCE.\n"
             "If the evidence does not contain the answer, you must state that you have insufficient evidence.\n"
             "Do not fabricate medical facts or citations.\n"
             "Return referenced_chunk_ids to indicate which specific chunks you derived the facts from."
            ),
            ("user", 
             "USER_QUERY: {query}\n\nRETRIEVED_MEDICAL_EVIDENCE:\n{context}"
            )
        ])

    @property
    def llm(self):
        key = self.api_key or get_gemini_api_key()
        if not key:
            return None
        if self._llm is None or self._cached_api_key != key:
            self._cached_api_key = key
            self._llm = ChatGoogleGenerativeAI(
                model=self.model_name,
                google_api_key=key,
                temperature=0.0
            ).with_structured_output(GeminiRawResponse)
        return self._llm

    @llm.setter
    def llm(self, value):
        self._llm = value
        self._cached_api_key = "EXPLICIT_OVERRIDE"

    def generate(self, query: str, context: str) -> GeminiRawResponse:
        if self.llm is None:
            logger.info("Gemini not configured; returning fallback GeminiRawResponse")
            return GeminiRawResponse(
                answer="AI response generation is currently unavailable because the Gemini API is not configured. Retrieved context is available in citations.",
                grounded=False,
                confidence="low",
                requires_professional_review=True,
                referenced_chunk_ids=[]
            )

        chain = self.prompt | self.llm
        try:
            return chain.invoke({"query": query, "context": context})
        except Exception as e:
            logger.warning(f"Gemini response generation failed: {type(e).__name__}; returning fallback")
            return GeminiRawResponse(
                answer="AI response generation failed due to service unavailability.",
                grounded=False,
                confidence="low",
                requires_professional_review=True,
                referenced_chunk_ids=[]
            )

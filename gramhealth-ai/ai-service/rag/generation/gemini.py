from typing import List
from pydantic import BaseModel, Field
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from ..models.schemas import RetrievalResult

# Model output schema (raw from Gemini)
class GeminiRawResponse(BaseModel):
    answer: str = Field(description="The grounded answer to the query based ONLY on the evidence.")
    grounded: bool = Field(description="True if the answer is grounded in the provided evidence.")
    confidence: str = Field(description="high, moderate, or low")
    requires_professional_review: bool = Field(description="True if the user should consult a medical professional.")
    referenced_chunk_ids: List[str] = Field(description="List of Chunk IDs explicitly used to formulate the answer.")

class GeminiGenerator:
    def __init__(self, api_key: str, model_name: str = "gemini-3.6-flash"):
        self.llm = ChatGoogleGenerativeAI(
            model=model_name,
            google_api_key=api_key,
            temperature=0.0
        ).with_structured_output(GeminiRawResponse)

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

    def generate(self, query: str, context: str) -> GeminiRawResponse:
        chain = self.prompt | self.llm
        return chain.invoke({"query": query, "context": context})

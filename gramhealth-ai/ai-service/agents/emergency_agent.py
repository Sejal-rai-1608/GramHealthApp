from pydantic import BaseModel, Field
from typing import Literal
from langchain_google_genai import ChatGoogleGenerativeAI
from rag.config.settings import settings

class EmergencyResponse(BaseModel):
    is_emergency: bool = Field(description="Whether the situation requires immediate medical attention.")
    urgency: Literal["emergency", "urgent", "normal"] = Field(description="Urgency of the situation.")
    response: str = Field(description="The textual response advising the user.")
    recommended_action: str = Field(description="Specific action the user should take immediately.")
    requires_professional_review: bool = Field(default=True, description="Always true for emergencies.")

class EmergencyAgent:
    def __init__(self):
        self.llm = ChatGoogleGenerativeAI(
            model=settings.gemini_model,
            google_api_key=settings.gemini_api_key,
            temperature=0.0
        ).with_structured_output(EmergencyResponse)

    def execute(self, query: str) -> EmergencyResponse:
        prompt = f"""You are an Emergency Agent.
Your responsibility is to detect emergency/risk patterns, prioritize immediate safety, and clearly tell the user when urgent/emergency care may be appropriate.
IMPORTANT SAFETY RULES:
- Avoid delaying emergency action with unnecessary reasoning.
- Do NOT diagnose, simply prioritize safety.
- Tell the user to call emergency services or go to the nearest emergency room if severe symptoms (e.g. severe chest pain, difficulty breathing, stroke signs) are present.

User Query: {query}
"""
        return self.llm.invoke(prompt)

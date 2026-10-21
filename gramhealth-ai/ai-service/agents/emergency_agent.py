import logging
from pydantic import BaseModel, Field
from typing import Literal, Optional
from langchain_google_genai import ChatGoogleGenerativeAI
from rag.config.settings import settings, get_gemini_api_key

logger = logging.getLogger(__name__)

class EmergencyResponse(BaseModel):
    is_emergency: bool = Field(description="Whether the situation requires immediate medical attention.")
    urgency: Literal["emergency", "urgent", "normal"] = Field(description="Urgency of the situation.")
    response: str = Field(description="The textual response advising the user.")
    recommended_action: str = Field(description="Specific action the user should take immediately.")
    requires_professional_review: bool = Field(default=True, description="Always true for emergencies.")

class EmergencyAgent:
    def __init__(self):
        self._llm = None
        self._cached_api_key = None

    @property
    def llm(self):
        api_key = get_gemini_api_key()
        if not api_key:
            return None
        if self._llm is None or self._cached_api_key != api_key:
            self._cached_api_key = api_key
            self._llm = ChatGoogleGenerativeAI(
                model=settings.gemini_model,
                google_api_key=api_key,
                temperature=0.0
            ).with_structured_output(EmergencyResponse)
        return self._llm

    @llm.setter
    def llm(self, value):
        self._llm = value
        self._cached_api_key = "EXPLICIT_OVERRIDE"

    def execute(self, query: str) -> EmergencyResponse:
        # Deterministic emergency fallback if Gemini is not configured
        if self.llm is None:
            logger.info("Gemini not configured; using deterministic EmergencyResponse")
            return EmergencyResponse(
                is_emergency=True,
                urgency="emergency",
                response="EMERGENCY ALERT: Severe symptoms detected that require immediate medical attention.",
                recommended_action="Call 911 or your local emergency services immediately, or go to the nearest emergency room.",
                requires_professional_review=True
            )

        prompt = f"""You are an Emergency Agent.
Your responsibility is to detect emergency/risk patterns, prioritize immediate safety, and clearly tell the user when urgent/emergency care may be appropriate.
IMPORTANT SAFETY RULES:
- Avoid delaying emergency action with unnecessary reasoning.
- Do NOT diagnose, simply prioritize safety.
- Tell the user to call emergency services or go to the nearest emergency room if severe symptoms (e.g. severe chest pain, difficulty breathing, stroke signs) are present.

User Query: {query}
"""
        try:
            return self.llm.invoke(prompt)
        except Exception as e:
            logger.warning(f"Emergency LLM invocation failed: {type(e).__name__}; using deterministic emergency response")
            return EmergencyResponse(
                is_emergency=True,
                urgency="emergency",
                response="EMERGENCY ALERT: Severe symptoms detected that require immediate medical attention.",
                recommended_action="Call 911 or your local emergency services immediately, or go to the nearest emergency room.",
                requires_professional_review=True
            )

import json
import logging
from typing import List, Dict, Any, Literal, Optional
from pydantic import BaseModel, Field
from langchain_google_genai import ChatGoogleGenerativeAI
from rag.config.settings import settings, get_gemini_api_key

logger = logging.getLogger(__name__)

class ClinicalReasonResponse(BaseModel):
    answer: str = Field(description="The textual clinical reasoning response provided by the agent.")
    confidence: Literal["low", "medium", "high"] = Field(description="Confidence level of the response.")
    requires_professional_review: bool = Field(description="Whether a doctor needs to review this situation.")
    grounded: bool = Field(description="True if the response is fully supported by the retrieved medical/patient evidence. False if there was no evidence or it was insufficient.")
    sources: List[str] = Field(description="List of chunk_ids that directly support the reasoning.", default=[])
    risk_level: Literal["low", "moderate", "high"] = Field(description="Assessed risk level.", default="low")
    recommended_next_step: str = Field(description="Recommended next step for the patient.", default="")

# Backwards compatibility alias
ClinicalReasoningResponse = ClinicalReasonResponse

class ClinicalAgent:
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
                temperature=0.0,
                max_retries=1
            ).with_structured_output(ClinicalReasonResponse)
        return self._llm

    @llm.setter
    def llm(self, value):
        self._llm = value
        self._cached_api_key = "EXPLICIT_OVERRIDE"

    def reason(self, query: str, patient_evidence: List[Dict[str, Any]], medical_evidence: List[Dict[str, Any]]) -> Dict[str, Any]:
        # Collect chunk IDs from evidence if available
        available_sources = []
        if medical_evidence:
            available_sources.extend([e.get("chunk_id") for e in medical_evidence if e.get("chunk_id")])
        if patient_evidence:
            available_sources.extend([e.get("chunk_id") for e in patient_evidence if e.get("chunk_id")])

        # If Gemini is not configured, return controlled unavailable state
        if self.llm is None:
            logger.info("Gemini not configured; returning controlled LLM unavailable state for clinical reasoning")
            return {
                "answer": "AI reasoning service is currently unavailable because the Gemini API is not configured.",
                "confidence": "low",
                "requires_professional_review": True,
                "grounded": False,
                "sources": available_sources,
                "risk_level": "moderate",
                "recommended_next_step": "Please consult a qualified healthcare professional.",
                "error": "LLM_UNAVAILABLE"
            }

        patient_context_str = json.dumps(patient_evidence, indent=2, ensure_ascii=False) if patient_evidence else "No patient context retrieved."
        medical_context_str = json.dumps(medical_evidence, indent=2, ensure_ascii=False) if medical_evidence else "No medical knowledge retrieved."
        
        prompt = f"""You are the Clinical Reasoning Layer.
Your responsibility is to analyze the user's query using ONLY the provided evidence.

PATIENT EVIDENCE:
{patient_context_str}

MEDICAL KNOWLEDGE EVIDENCE:
{medical_context_str}

IMPORTANT SAFETY RULES:
- Distinguish between what the patient's records say and what external medical knowledge says.
- Do not invent diagnoses, patient history, lab values, or unsupported facts.
- If the retrieved evidence does not contain sufficient information to answer safely, state that explicitly and set grounded=False.
- Recommend professional evaluation when appropriate.
- Cite the source chunk_ids in the 'sources' field if you relied on them.

User Query: {query}
"""
        try:
            result = self.llm.invoke(prompt)
            return {
                "answer": result.answer,
                "confidence": result.confidence,
                "requires_professional_review": result.requires_professional_review,
                "grounded": result.grounded,
                "sources": result.sources,
                "risk_level": result.risk_level,
                "recommended_next_step": result.recommended_next_step
            }
        except Exception as e:
            logger.warning(f"Clinical reasoning LLM invocation failed: {type(e).__name__}; returning controlled fallback")
            return {
                "answer": "AI reasoning service is currently unavailable.",
                "confidence": "low",
                "requires_professional_review": True,
                "grounded": False,
                "sources": available_sources,
                "risk_level": "moderate",
                "recommended_next_step": "Please consult a healthcare professional.",
                "error": f"LLM_ERROR: {type(e).__name__}"
            }

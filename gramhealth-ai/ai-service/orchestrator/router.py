import logging
from typing import List, Literal, Optional
from pydantic import BaseModel, Field
from langchain_google_genai import ChatGoogleGenerativeAI
from rag.config.settings import settings, get_gemini_api_key

logger = logging.getLogger(__name__)

class RouteClassification(BaseModel):
    intent: Literal["clinical", "emergency", "unsupported"] = Field(
        description="The primary intent of the user's query."
    )
    urgency: Literal["emergency", "urgent", "normal"] = Field(
        description="The urgency of the medical situation."
    )
    requires_patient_context: bool = Field(
        description="True if answering requires retrieving the patient's unstructured historical records (e.g. past consultations, notes, symptoms)."
    )
    requires_medical_knowledge: bool = Field(
        description="True if answering requires fetching factual, trusted medical guidelines or external knowledge."
    )
    requires_structured_patient_lookup: bool = Field(
        default=False,
        description="True if the request explicitly asks for an exact structured patient fact (e.g., 'latest hemoglobin', 'my blood pressure')."
    )
    symptoms: Optional[List[str]] = Field(
        default=None, description="Any symptoms extracted from the query."
    )
    routing_method: Optional[str] = None
    selected_agent: Optional[str] = None # We will derive this in classify()

class IntentRouter:
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
            ).with_structured_output(RouteClassification)
        return self._llm

    @llm.setter
    def llm(self, value):
        self._llm = value
        self._cached_api_key = "EXPLICIT_OVERRIDE"

    def classify(self, query: str) -> RouteClassification:
        query_lower = query.lower()
        
        # 1. Emergency detection (deterministic, never requires Gemini)
        emergency_keywords = ["severe chest pain", "difficulty breathing", "severe bleeding", "stroke", "heart attack", "emergency", "911"]
        if any(keyword in query_lower for keyword in emergency_keywords):
            result = RouteClassification(
                intent="emergency",
                urgency="emergency",
                requires_patient_context=False,
                requires_medical_knowledge=False,
                requires_structured_patient_lookup=False,
                routing_method="deterministic"
            )
            result.selected_agent = self._derive_route(result)
            return result
            
        # 2. Clearly unsupported requests (deterministic, never requires Gemini)
        unsupported_phrases = ["repair a car engine", "fix a car", "car engine"]
        if any(phrase in query_lower for phrase in unsupported_phrases):
            result = RouteClassification(
                intent="unsupported",
                urgency="normal",
                requires_patient_context=False,
                requires_medical_knowledge=False,
                requires_structured_patient_lookup=False,
                routing_method="deterministic"
            )
            result.selected_agent = self._derive_route(result)
            return result

        # 3. LLM classification if Gemini is configured; otherwise controlled fallback
        if self.llm is None:
            logger.info("Gemini not configured; routing to clinical_agent with llm_unavailable state")
            result = RouteClassification(
                intent="clinical",
                urgency="normal",
                requires_patient_context=False,
                requires_medical_knowledge=False,
                requires_structured_patient_lookup=False,
                routing_method="llm_unavailable"
            )
            result.selected_agent = self._derive_route(result)
            return result

        prompt = f"""You are a medical triage and routing classifier.
Analyze the user's query and classify their information needs.

Rules for intent:
- emergency: Severe symptoms, emergency warning signs, urgent medical situations. MUST set urgency to 'emergency'.
- unsupported: Non-medical or completely unsupported requests.
- clinical: Any valid medical request that is not an emergency or unsupported.

Rules for information needs:
- requires_patient_context: True if the query asks about or requires previous history, past consultations, or past symptoms (e.g., 'last time I had dengue', 'my previous consultation').
- requires_medical_knowledge: True ONLY if the query explicitly asks for clinical guidelines, medical literature, specific disease protocols, or complex factual medical questions requiring trusted external evidence (e.g., 'What are the WHO criteria for Dengue?', 'What is the dosage of paracetamol for adults?'). False for general symptom checking, personal health inquiries, or triage (e.g., 'I have fever and headache, what could it be?').
- requires_structured_patient_lookup: True if they ask for a very specific measured fact (e.g. 'latest platelet count', 'last hemoglobin level').

Query: {query}
"""
        try:
            result = self.llm.invoke(prompt)
            result.routing_method = "llm"
            result.selected_agent = self._derive_route(result)
            return result
        except Exception as e:
            logger.warning(f"Gemini intent classification failed: {type(e).__name__}. Falling back to clinical_agent.")
            result = RouteClassification(
                intent="clinical",
                urgency="normal",
                requires_patient_context=False,
                requires_medical_knowledge=False,
                requires_structured_patient_lookup=False,
                routing_method="llm_unavailable"
            )
            result.selected_agent = self._derive_route(result)
            return result

    def _derive_route(self, c: RouteClassification) -> str:
        """Derives the execution route based on information requirements."""
        if c.intent == "emergency" or c.urgency == "emergency":
            return "emergency_agent"
            
        if c.intent == "unsupported":
            return "unsupported"
            
        if c.requires_structured_patient_lookup:
            return "structured_lookup"
            
        if c.requires_patient_context and c.requires_medical_knowledge:
            return "hybrid_rag"
            
        if c.requires_patient_context:
            return "patient_rag"
            
        if c.requires_medical_knowledge:
            return "medical_rag"
            
        # No special context needed -> raw clinical agent
        return "clinical_agent"

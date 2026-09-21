from typing import List, Literal, Optional
from pydantic import BaseModel, Field
from langchain_google_genai import ChatGoogleGenerativeAI
from rag.config.settings import settings

class RouteClassification(BaseModel):
<<<<<<< HEAD
    intent: Literal["clinical", "emergency", "rag", "unsupported"] = Field(
=======
    intent: Literal["clinical", "emergency", "unsupported"] = Field(
>>>>>>> f9f5067 (Initial commit)
        description="The primary intent of the user's query."
    )
    urgency: Literal["emergency", "urgent", "normal"] = Field(
        description="The urgency of the medical situation."
    )
<<<<<<< HEAD
    selected_agent: Literal["clinical_agent", "emergency_agent", "rag_agent", "unsupported"] = Field(
        description="The target agent to route this request to."
=======
    requires_patient_context: bool = Field(
        description="True if answering requires retrieving the patient's unstructured historical records (e.g. past consultations, notes, symptoms)."
    )
    requires_medical_knowledge: bool = Field(
        description="True if answering requires fetching factual, trusted medical guidelines or external knowledge."
    )
    requires_structured_patient_lookup: bool = Field(
        default=False,
        description="True if the request explicitly asks for an exact structured patient fact (e.g., 'latest hemoglobin', 'my blood pressure')."
>>>>>>> f9f5067 (Initial commit)
    )
    symptoms: Optional[List[str]] = Field(
        default=None, description="Any symptoms extracted from the query."
    )
    routing_method: Optional[str] = None
<<<<<<< HEAD
=======
    selected_agent: Optional[str] = None # We will derive this in classify()
>>>>>>> f9f5067 (Initial commit)

class IntentRouter:
    def __init__(self):
        self.llm = ChatGoogleGenerativeAI(
            model=settings.gemini_model,
            google_api_key=settings.gemini_api_key,
            temperature=0.0
        ).with_structured_output(RouteClassification)

    def classify(self, query: str) -> RouteClassification:
        query_lower = query.lower()
        
        # 1. Emergency detection
        emergency_keywords = ["severe chest pain", "difficulty breathing", "severe bleeding", "stroke", "heart attack", "emergency", "911"]
        if any(keyword in query_lower for keyword in emergency_keywords):
<<<<<<< HEAD
            return RouteClassification(
                intent="emergency",
                urgency="emergency",
                selected_agent="emergency_agent",
                routing_method="deterministic"
            )
            
        # 2. RAG/document intent detection
        rag_phrases = [
            "according to the document",
            "according to who",
            "medical knowledge base",
            "what does the document say",
            "based on the uploaded document"
        ]
        if any(phrase in query_lower for phrase in rag_phrases):
            return RouteClassification(
                intent="rag",
                urgency="normal",
                selected_agent="rag_agent",
                routing_method="deterministic"
            )
            
        # 3. Clearly unsupported requests
        unsupported_phrases = ["repair a car engine", "fix a car", "car engine"]
        if any(phrase in query_lower for phrase in unsupported_phrases):
            return RouteClassification(
                intent="unsupported",
                urgency="normal",
                selected_agent="unsupported",
                routing_method="deterministic"
            )

        # 4. Fallback to LLM
        prompt = f"""You are a medical triage and routing classifier.
Analyze the user's query and route it to the appropriate agent.

Routes:
- clinical: Symptoms, common health questions, disease info, medication/treatment questions. Routes to 'clinical_agent'.
- emergency: Severe symptoms, emergency warning signs, urgent medical situations. Routes to 'emergency_agent'. MUST set urgency to 'emergency'.
- rag: Factual medical questions requiring evidence from the approved medical knowledge base (e.g. 'According to the document...'). Routes to 'rag_agent'.
- unsupported: Non-medical or unsupported requests (e.g. 'How do I repair a car engine?'). Routes to 'unsupported'.

Emergency situations (severe chest pain, difficulty breathing, severe bleeding, stroke symptoms) MUST be routed to 'emergency' and 'emergency_agent'.
=======
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
            
        # 2. Clearly unsupported requests
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

        # 3. Fallback to LLM for Information Needs Classification
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
>>>>>>> f9f5067 (Initial commit)

Query: {query}
"""
        result = self.llm.invoke(prompt)
        result.routing_method = "llm"
<<<<<<< HEAD
        return result
=======
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
>>>>>>> f9f5067 (Initial commit)

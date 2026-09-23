from typing import TypedDict, Optional, List, Dict, Any

class AgentState(TypedDict):
    # Input
    user_query: str
    patient_context: Optional[Dict[str, Any]] # e.g. {"patient_id": "P123"}
    
    # Classification
    intent: Optional[str]
    urgency: Optional[str]
    symptoms: Optional[List[str]]
    requires_patient_context: Optional[bool]
    requires_medical_knowledge: Optional[bool]
    requires_structured_patient_lookup: Optional[bool]
    
    # Routing
    selected_agent: Optional[str]
    routing_method: Optional[str]
    
    # RAG specific evidence
    patient_evidence: Optional[List[Dict[str, Any]]]
    medical_evidence: Optional[List[Dict[str, Any]]]
    
    # Final structured response
    agent_response: Optional[str]
    final_response: Optional[str]
    sources: Optional[List[Any]] # Citations/Metadata
    grounded: Optional[bool]
    confidence: Optional[str]
    urgency_out: Optional[str]
    requires_professional_review: Optional[bool]
    
    # Execution
    error: Optional[str]
    graph_path: Optional[List[str]]

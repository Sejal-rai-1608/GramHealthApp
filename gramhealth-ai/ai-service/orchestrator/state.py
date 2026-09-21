<<<<<<< HEAD
from typing import TypedDict, Annotated, Optional, List, Dict, Any
=======
from typing import TypedDict, Optional, List, Dict, Any
>>>>>>> f9f5067 (Initial commit)

class AgentState(TypedDict):
    # Input
    user_query: str
<<<<<<< HEAD
=======
    patient_context: Optional[Dict[str, Any]] # e.g. {"patient_id": "P123"}
>>>>>>> f9f5067 (Initial commit)
    
    # Classification
    intent: Optional[str]
    urgency: Optional[str]
    symptoms: Optional[List[str]]
<<<<<<< HEAD
    patient_context: Optional[Dict[str, Any]]
=======
    requires_patient_context: Optional[bool]
    requires_medical_knowledge: Optional[bool]
    requires_structured_patient_lookup: Optional[bool]
>>>>>>> f9f5067 (Initial commit)
    
    # Routing
    selected_agent: Optional[str]
    routing_method: Optional[str]
    
<<<<<<< HEAD
    # RAG specific
    retrieved_evidence: Optional[List[str]]
    
    # Agent output
    agent_response: Optional[str]
    
    # Final structured response
    final_response: Optional[str]
    sources: Optional[List[str]]
    grounded: Optional[bool]
    confidence: Optional[str]
=======
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
>>>>>>> f9f5067 (Initial commit)
    requires_professional_review: Optional[bool]
    
    # Execution
    error: Optional[str]
    graph_path: Optional[List[str]]

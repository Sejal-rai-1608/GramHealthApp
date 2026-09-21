<<<<<<< HEAD
from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing import Optional, List, Any
=======
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List, Any, Dict
>>>>>>> f9f5067 (Initial commit)
import time
import logging
from orchestrator import multi_agent_graph
from rag.models.schemas import Citation

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/agent", tags=["Agent"])

class AgentQueryRequest(BaseModel):
    query: str = Field(..., json_schema_extra={"example": "I have fever and headache. What could this mean?"})
<<<<<<< HEAD
=======
    # This represents the trusted authenticated patient identity coming from the Node.js backend.
    patient_id: Optional[str] = Field(None, json_schema_extra={"example": "P123"})
>>>>>>> f9f5067 (Initial commit)

class AgentQueryResponse(BaseModel):
    query: str
    intent: Optional[str] = Field(None, json_schema_extra={"example": "clinical"})
    agent: Optional[str] = Field(None, json_schema_extra={"example": "clinical_agent"})
    answer: Optional[str] = Field(None, json_schema_extra={"example": "Fever and headache are common symptoms..."})
    grounded: Optional[bool] = Field(None, json_schema_extra={"example": False})
    confidence: Optional[str] = Field(None, json_schema_extra={"example": "high"})
    urgency: Optional[str] = Field(None, json_schema_extra={"example": "normal"})
    requires_professional_review: Optional[bool] = Field(None, json_schema_extra={"example": True})
<<<<<<< HEAD
    sources: Optional[List[Citation]] = []
=======
    
    # Evidence Provenance
    evidence: Optional[Dict[str, List[Any]]] = Field(default_factory=lambda: {"patient": [], "medical": []})
    
    sources: Optional[List[str]] = []
>>>>>>> f9f5067 (Initial commit)
    routing_method: Optional[str] = Field(None, json_schema_extra={"example": "llm"})
    graph_path: Optional[List[str]] = Field([], json_schema_extra={"example": ["classify_request", "clinical_agent", "finalize_response"]})

@router.post("/query", response_model=AgentQueryResponse, description="Process a medical query through the multi-agent AI orchestrator.")
def query_agent(request: AgentQueryRequest):
    start_time = time.time()
    logger.info(f"AgentQueryRequest received: {request.query}")
    try:
<<<<<<< HEAD
        initial_state = {"user_query": request.query}
=======
        initial_state = {
            "user_query": request.query,
            "patient_context": {"patient_id": request.patient_id} if request.patient_id else None
        }
>>>>>>> f9f5067 (Initial commit)
        final_state = multi_agent_graph.invoke(initial_state)
        
        latency = round((time.time() - start_time) * 1000, 2)
        logger.info(f"AgentQueryResponse success intent={final_state.get('intent')} agent={final_state.get('selected_agent')} routing_method={final_state.get('routing_method')} graph_path={final_state.get('graph_path')} latency_ms={latency}")
        
        return AgentQueryResponse(
            query=request.query,
            intent=final_state.get("intent"),
            agent=final_state.get("selected_agent"),
            answer=final_state.get("final_response"),
            grounded=final_state.get("grounded", False),
            confidence=final_state.get("confidence"),
            urgency=final_state.get("urgency"),
            requires_professional_review=final_state.get("requires_professional_review", False),
<<<<<<< HEAD
=======
            evidence={
                "patient": final_state.get("patient_evidence", []),
                "medical": final_state.get("medical_evidence", [])
            },
>>>>>>> f9f5067 (Initial commit)
            sources=final_state.get("sources", []),
            routing_method=final_state.get("routing_method"),
            graph_path=final_state.get("graph_path", [])
        )
    except Exception as e:
<<<<<<< HEAD
        latency = round((time.time() - start_time) * 1000, 2)
        logger.error(f"AgentQueryResponse failure latency_ms={latency} error={str(e)}")
        raise
=======
        logger.error(f"Agent routing failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal AI Service Error: {str(e)}")
>>>>>>> f9f5067 (Initial commit)

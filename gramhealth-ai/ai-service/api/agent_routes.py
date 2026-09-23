from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, Field
from typing import Optional, List, Any, Dict
import time
import logging
from orchestrator import multi_agent_graph
from rag.models.schemas import Citation

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/agent", tags=["Agent"])

class AgentQueryRequest(BaseModel):
    query: str = Field(..., json_schema_extra={"example": "I have fever and headache. What could this mean?"})
    # This represents the trusted authenticated patient identity coming from the Node.js backend.
    patient_id: Optional[str] = Field(None, json_schema_extra={"example": "P123"})

class AgentQueryResponse(BaseModel):
    query: str
    intent: Optional[str] = Field(None, json_schema_extra={"example": "clinical"})
    agent: Optional[str] = Field(None, json_schema_extra={"example": "clinical_agent"})
    answer: Optional[str] = Field(None, json_schema_extra={"example": "Fever and headache are common symptoms..."})
    grounded: Optional[bool] = Field(None, json_schema_extra={"example": False})
    confidence: Optional[str] = Field(None, json_schema_extra={"example": "high"})
    urgency: Optional[str] = Field(None, json_schema_extra={"example": "normal"})
    requires_professional_review: Optional[bool] = Field(None, json_schema_extra={"example": True})
    
    # Evidence Provenance
    evidence: Optional[Dict[str, List[Any]]] = Field(default_factory=lambda: {"patient": [], "medical": []})
    
    sources: Optional[List[str]] = []
    routing_method: Optional[str] = Field(None, json_schema_extra={"example": "llm"})
    graph_path: Optional[List[str]] = Field([], json_schema_extra={"example": ["classify_request", "clinical_agent", "finalize_response"]})
    error: Optional[str] = None

@router.post("/query", response_model=AgentQueryResponse, description="Process a medical query through the multi-agent AI orchestrator.")
def query_agent(request: AgentQueryRequest, x_request_id: Optional[str] = Header(None)):
    start_time = time.time()
    req_id = x_request_id or "NO_REQ_ID"
    q_len = len(request.query) if request.query else 0
    has_patient = bool(request.patient_id)

    print(f"[FastAPI] Request ID: {req_id}")
    print(f"[FastAPI] POST /agent/query")
    print(f"[FastAPI] query length: {q_len}")
    print(f"[FastAPI] patient_id presence: {has_patient}")
    logger.info(f"[FastAPI] Request ID: {req_id}, query length: {q_len}, patient_id presence: {has_patient}")

    try:
        initial_state = {
            "user_query": request.query,
            "patient_context": {"patient_id": request.patient_id} if request.patient_id else None
        }
        final_state = multi_agent_graph.invoke(initial_state)
        
        latency = round((time.time() - start_time) * 1000, 2)
        intent = final_state.get("intent")
        selected_route = final_state.get("selected_agent")
        final_agent = selected_route
        routing_method = final_state.get("routing_method")
        answer = final_state.get("final_response") or ""
        error = final_state.get("error")

        print(f"[FastAPI] Request ID: {req_id}")
        print(f"[FastAPI] classification intent: {intent}")
        print(f"[FastAPI] selected route: {selected_route}")
        print(f"[FastAPI] final agent: {final_agent}")
        print(f"[FastAPI] response generated: {answer[:60]}... (len={len(answer)})")
        logger.info(f"[FastAPI] Success: intent={intent}, agent={final_agent}, routing_method={routing_method}, latency_ms={latency}")

        # If LLM execution experienced an internal failure, return HTTP 503 instead of disguising as healthy advice
        if error and ("LLM_ERROR" in str(error) or "LLM_UNAVAILABLE" in str(error)):
            logger.warning(f"[FastAPI] LLM failure encountered: {error}")
            raise HTTPException(status_code=503, detail=f"AI reasoning service error: {error}")

        return AgentQueryResponse(
            query=request.query,
            intent=intent,
            agent=final_agent,
            answer=answer,
            grounded=final_state.get("grounded", False),
            confidence=final_state.get("confidence"),
            urgency=final_state.get("urgency"),
            requires_professional_review=final_state.get("requires_professional_review", False),
            evidence={
                "patient": final_state.get("patient_evidence", []),
                "medical": final_state.get("medical_evidence", [])
            },
            sources=final_state.get("sources", []),
            routing_method=routing_method,
            graph_path=final_state.get("graph_path", []),
            error=error
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[FastAPI] Agent routing failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal AI Service Error: {str(e)}")

import logging
from typing import Dict, Any, List

from .state import AgentState
from .router import IntentRouter
from agents import ClinicalAgent, EmergencyAgent
from rag.pipeline import RAGPipeline
from patient.rag import PatientRAGService
from patient.models import PatientContext

logger = logging.getLogger(__name__)

# Initialize singletons for the nodes to reuse
router = IntentRouter()
clinical_agent = ClinicalAgent()
emergency_agent = EmergencyAgent()
medical_rag = RAGPipeline()
patient_rag = PatientRAGService()

def classify_request(state: AgentState) -> AgentState:
    logger.info("NODE START: classify_request")
    logger.info(f"Classifying request: {state['user_query']}")
    classification = router.classify(state["user_query"])
    logger.info(f"ROUTING DIAGNOSTICS: intent={classification.intent}, urgency={classification.urgency}, selected_agent={classification.selected_agent}, routing_method={classification.routing_method}")
    logger.info("NODE END: classify_request")
    
    return {
        **state,
        "intent": classification.intent,
        "urgency": classification.urgency,
        "symptoms": classification.symptoms,
        "requires_patient_context": classification.requires_patient_context,
        "requires_medical_knowledge": classification.requires_medical_knowledge,
        "requires_structured_patient_lookup": classification.requires_structured_patient_lookup,
        "selected_agent": classification.selected_agent,
        "routing_method": classification.routing_method,
        "graph_path": state.get("graph_path", []) + ["classify_request"]
    }

def execute_patient_rag(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_patient_rag")
    logger.info("Routing to Patient RAG")
    if not state.get("patient_context"):
        logger.error("Missing patient context!")
        return {
            **state,
            "patient_evidence": [],
            "error": "Missing patient context for retrieval",
            "graph_path": state.get("graph_path", []) + ["patient_rag"]
        }
    
    ctx = PatientContext(**state["patient_context"])
    try:
        evidence = patient_rag.query(state["user_query"], ctx)
        return {
            **state,
            "patient_evidence": evidence,
            "graph_path": state.get("graph_path", []) + ["patient_rag"]
        }
    except Exception as e:
        logger.error(f"Patient RAG failed: {e}")
        return {
            **state,
            "patient_evidence": [],
            "error": str(e),
        }
    finally:
        logger.info("NODE END: execute_patient_rag")

def execute_medical_rag(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_medical_rag")
    logger.info("Routing to Medical RAG")
    # For medical RAG, we just want to retrieve context without Gemini generation.
    # The clinical agent will do the generation.
    from rag.config.settings import settings
    raw_results = medical_rag.vector_store.search_similarity(state["user_query"], top_k=settings.top_k)
    filtered_results = medical_rag.relevance_filter.filter_and_format(raw_results)
    
    evidence = []
    for res in filtered_results:
        evidence.append({
            "chunk_id": res.chunk_id,
            "text": res.text,
            "source_type": "medical_knowledge",
            "title": res.metadata.title,
            "publisher": res.metadata.publisher,
            "url": res.metadata.source_url
        })
        
    
    logger.info("NODE END: execute_medical_rag")
    return {
        **state,
        "medical_evidence": evidence,
        "graph_path": state.get("graph_path", []) + ["medical_rag"]
    }

def execute_hybrid_rag(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_hybrid_rag")
    logger.info("Routing to Hybrid RAG")
    # Run patient
    state = execute_patient_rag(state)
    # Run medical
    state = execute_medical_rag(state)
    
    # graph_path will have appended both, let's fix it by appending hybrid
    path = [p for p in state.get("graph_path", []) if p not in ["patient_rag", "medical_rag"]]
    logger.info("NODE END: execute_hybrid_rag")
    return {
        **state,
        "graph_path": path + ["hybrid_rag"]
    }

def execute_structured_lookup(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_structured_lookup")
    logger.info("Routing to Structured Lookup")
    # For demo purposes, mock a structured lookup response based on intent.
    logger.info("NODE END: execute_structured_lookup")
    return {
        **state,
        "agent_response": "According to your records, the requested structured fact is available (MOCKED).",
        "confidence": "high",
        "requires_professional_review": False,
        "grounded": True,
        "sources": [],
        "graph_path": state.get("graph_path", []) + ["structured_lookup"]
    }

def execute_clinical_agent(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_clinical_agent")
    logger.info("Routing to Clinical Reasoning Agent")
    # clinical_agent will now take patient_evidence and medical_evidence
    response = clinical_agent.reason(
        query=state["user_query"],
        patient_evidence=state.get("patient_evidence", []),
        medical_evidence=state.get("medical_evidence", [])
    )
    logger.info("NODE END: execute_clinical_agent")
    result_state = {
        **state,
        "agent_response": response.get("answer"),
        "confidence": response.get("confidence", "high"),
        "requires_professional_review": response.get("requires_professional_review", True),
        "grounded": response.get("grounded", False),
        "sources": response.get("sources", []),
        "graph_path": state.get("graph_path", []) + ["clinical_agent"]
    }
    if response.get("error"):
        result_state["error"] = response["error"]
    return result_state

def execute_emergency_agent(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_emergency_agent")
    logger.info("Routing to Emergency Agent")
    logger.info("Emergency detection result: True")
    logger.info("Emergency agent start")
    response = emergency_agent.execute(state["user_query"])
    logger.info("Emergency agent completion")
    logger.info("NODE END: execute_emergency_agent")
    return {
        **state,
        "agent_response": f"{response.response}\n\nRECOMMENDED ACTION: {response.recommended_action}",
        "confidence": "high",
        "requires_professional_review": response.requires_professional_review,
        "grounded": False,
        "sources": [],
        "graph_path": state.get("graph_path", []) + ["emergency_agent"]
    }

def execute_unsupported(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_unsupported")
    logger.info("Routing to Unsupported")
    logger.info("NODE END: execute_unsupported")
    return {
        **state,
        "agent_response": "I cannot help with this request as it is outside my supported medical scope.",
        "confidence": "high",
        "requires_professional_review": False,
        "grounded": False,
        "sources": [],
        "graph_path": state.get("graph_path", []) + ["unsupported"]
    }

def finalize_response(state: AgentState) -> AgentState:
    logger.info("NODE START: finalize_response")
    logger.info(f"REQUEST intent={state.get('intent')} agent={state.get('selected_agent')}")
    
    logger.info("NODE END: finalize_response")
    return {
        **state,
        "final_response": state.get("agent_response", "Error processing request."),
        "graph_path": state.get("graph_path", []) + ["finalize_response"]
    }

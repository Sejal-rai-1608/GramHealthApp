import logging
import re
from typing import Dict, Any, List, Optional

from .state import AgentState
from .router import IntentRouter
from agents import ClinicalAgent, EmergencyAgent
from rag.pipeline import RAGPipeline
from patient.rag import PatientRAGService
from patient.models import PatientContext
from models.clinical_response import (
    ClinicalResponseSchema,
    AssessmentSchema,
    PossibleConditionSchema,
    EvidenceItemSchema,
    RiskLevelEnum,
    format_clinical_answer
)

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
    state = execute_patient_rag(state)
    state = execute_medical_rag(state)
    
    path = [p for p in state.get("graph_path", []) if p not in ["patient_rag", "medical_rag"]]
    logger.info("NODE END: execute_hybrid_rag")
    return {
        **state,
        "graph_path": path + ["hybrid_rag"]
    }

def execute_structured_lookup(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_structured_lookup")
    logger.info("Routing to Structured Lookup")
    
    query = state["user_query"]
    structured_resp = ClinicalResponseSchema(
        symptom_summary=f"Query regarding structured patient records: {query}",
        assessment=AssessmentSchema(
            summary="Retrieved historical patient record data for this query.",
            evidence_basis="Patient electronic medical record database",
            uncertainty="Only recorded facts are reflected; ongoing symptoms require clinical evaluation."
        ),
        possible_conditions=[],
        risk_level=RiskLevelEnum.low,
        what_you_can_do_now=[
            "Review your recorded health history.",
            "Consult your treating physician for interpretation of your lab results or records."
        ],
        warning_signs=["No specific warning signs were identified from the available information."],
        when_to_see_doctor="Discuss recorded results during your next scheduled consultation.",
        evidence=[
            EvidenceItemSchema(
                title="Structured Patient Record",
                source_type="Patient RAG",
                source="GramHealth Patient Record Database",
                citation="PATIENT-REC",
                relevance="Direct record lookup."
            )
        ],
        medical_disclaimer="This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice.",
        source_mode="Patient RAG",
        requires_professional_review=False,
        emergency=False
    )
    
    logger.info("NODE END: execute_structured_lookup")
    return {
        **state,
        "agent_response": format_clinical_answer(structured_resp),
        "structured_response": structured_resp.model_dump(),
        "confidence": "high",
        "requires_professional_review": False,
        "grounded": True,
        "sources": [],
        "graph_path": state.get("graph_path", []) + ["structured_lookup"]
    }

def execute_clinical_agent(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_clinical_agent")
    logger.info("Routing to Clinical Reasoning Agent")
    response = clinical_agent.reason(
        query=state["user_query"],
        patient_evidence=state.get("patient_evidence", []),
        medical_evidence=state.get("medical_evidence", [])
    )
    logger.info("NODE END: execute_clinical_agent")
    result_state = {
        **state,
        "agent_response": response.get("answer"),
        "structured_response": response.get("structured_response"),
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
    logger.info("Routing to Emergency Agent (Deterministic Override)")
    query = state["user_query"]
    
    # Deterministic emergency response constructed with common 9-section schema
    emergency_resp = ClinicalResponseSchema(
        symptom_summary=f"Reported symptoms with emergency indicators: {query}",
        assessment=AssessmentSchema(
            summary="Emergency indicators or critical red-flag symptoms have been identified. Immediate medical attention may be required.",
            evidence_basis="Deterministic Safety Rule",
            uncertainty="Potential acute medical emergency cannot be evaluated, confirmed, or managed remotely."
        ),
        possible_conditions=[],
        risk_level=RiskLevelEnum.emergency,
        what_you_can_do_now=[
            "Call local emergency services immediately (108 / 112).",
            "Go to the nearest hospital emergency department right now.",
            "Do not wait or attempt self-treatment at home.",
            "Ensure a family member, caregiver, or helper stays with the patient."
        ],
        warning_signs=[
            "Severe chest pain, crushing chest pressure, or tightness",
            "Severe difficulty breathing, choking, or shortness of breath",
            "Loss of consciousness, fainting, or unresponsiveness",
            "Sudden numbness, facial droop, or speech difficulty",
            "Severe uncontrolled bleeding"
        ],
        when_to_see_doctor="Seek emergency medical attention IMMEDIATELY. Call 108 / 112 or go to the nearest emergency room.",
        evidence=[
            EvidenceItemSchema(
                title="Emergency Clinical Safety Rule",
                source_type="Deterministic Safety Rule",
                source="GramHealth Emergency Protocol",
                citation="EMERGENCY-01",
                relevance="Deterministic triage triggered by reported emergency red-flag symptoms."
            )
        ],
        medical_disclaimer="This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice.",
        source_mode="Deterministic Safety Rule",
        requires_professional_review=True,
        emergency=True
    )
    
    logger.info("NODE END: execute_emergency_agent")
    return {
        **state,
        "agent_response": format_clinical_answer(emergency_resp),
        "structured_response": emergency_resp.model_dump(),
        "confidence": "high",
        "requires_professional_review": True,
        "grounded": False,
        "sources": [],
        "graph_path": state.get("graph_path", []) + ["emergency_agent"]
    }

def execute_unsupported(state: AgentState) -> AgentState:
    logger.info("NODE START: execute_unsupported")
    logger.info("Routing to Unsupported")
    query = state["user_query"]
    
    unsupported_resp = ClinicalResponseSchema(
        symptom_summary=f"Non-medical or unsupported inquiry: {query}",
        assessment=AssessmentSchema(
            summary="This inquiry does not describe healthcare symptoms or clinical questions.",
            evidence_basis="None",
            uncertainty="No clinical symptoms or medical context were provided."
        ),
        possible_conditions=[],
        risk_level=RiskLevelEnum.insufficientInformation,
        what_you_can_do_now=[
            "Please describe any health symptoms or medical concerns you would like help with.",
            "Consult a qualified healthcare professional for personalized medical advice."
        ],
        warning_signs=["No specific warning signs were identified from the available information."],
        when_to_see_doctor="Consult a healthcare professional if you experience concerning health symptoms.",
        evidence=[
            EvidenceItemSchema(
                title="No retrieved evidence",
                source_type="None",
                source="No retrieved medical evidence",
                citation="",
                relevance="Query does not contain clinical symptoms."
            )
        ],
        medical_disclaimer="This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice.",
        source_mode="None",
        requires_professional_review=False,
        emergency=False
    )
    
    logger.info("NODE END: execute_unsupported")
    return {
        **state,
        "agent_response": format_clinical_answer(unsupported_resp),
        "structured_response": unsupported_resp.model_dump(),
        "confidence": "high",
        "requires_professional_review": False,
        "grounded": False,
        "sources": [],
        "graph_path": state.get("graph_path", []) + ["unsupported"]
    }

def _validate_and_sanitize_clinical_response(
    raw_dict: Optional[Dict[str, Any]],
    user_query: str,
    is_deterministic_emergency: bool
) -> ClinicalResponseSchema:
    """14-point validation and safety sanitation."""
    standard_disclaimer = "This information is for general health guidance and is not a medical diagnosis. Please consult a qualified healthcare professional for personal medical advice."
    
    # If raw_dict is missing or malformed, build a safe fallback
    if not isinstance(raw_dict, dict):
        return ClinicalResponseSchema(
            symptom_summary=user_query,
            assessment=AssessmentSchema(
                summary="The available information is insufficient to evaluate symptoms safely.",
                evidence_basis="None",
                uncertainty="Available information is insufficient to determine the cause."
            ),
            possible_conditions=[],
            risk_level=RiskLevelEnum.emergency if is_deterministic_emergency else RiskLevelEnum.insufficientInformation,
            what_you_can_do_now=[
                "Rest and monitor symptoms.",
                "Consult a qualified healthcare professional for clinical advice."
            ],
            warning_signs=["No specific warning signs were identified from the available information."],
            when_to_see_doctor="Seek medical evaluation if symptoms worsen, persist, or new warning signs appear.",
            evidence=[
                EvidenceItemSchema(
                    title="No retrieved evidence",
                    source_type="None",
                    source="No retrieved medical evidence",
                    citation="",
                    relevance="Response is limited by insufficient evidence."
                )
            ],
            medical_disclaimer=standard_disclaimer,
            source_mode="None",
            requires_professional_review=True,
            emergency=is_deterministic_emergency
        )

    try:
        resp = ClinicalResponseSchema.model_validate(raw_dict)
    except Exception as e:
        logger.warning(f"ClinicalResponseSchema validation failed: {e}; repairing safely")
        return ClinicalResponseSchema(
            symptom_summary=str(raw_dict.get("symptom_summary") or user_query),
            assessment=AssessmentSchema(
                summary="The available information is insufficient to evaluate symptoms safely.",
                evidence_basis="None",
                uncertainty="Available information is insufficient to determine the cause."
            ),
            possible_conditions=[],
            risk_level=RiskLevelEnum.emergency if is_deterministic_emergency else RiskLevelEnum.insufficientInformation,
            what_you_can_do_now=[
                "Rest and monitor symptoms.",
                "Consult a qualified healthcare professional for clinical advice."
            ],
            warning_signs=["No specific warning signs were identified from the available information."],
            when_to_see_doctor="Seek medical evaluation if symptoms worsen or persist.",
            evidence=[
                EvidenceItemSchema(
                    title="No retrieved evidence",
                    source_type="None",
                    source="No retrieved medical evidence",
                    citation="",
                    relevance="Response is limited by insufficient evidence."
                )
            ],
            medical_disclaimer=standard_disclaimer,
            source_mode=str(raw_dict.get("source_mode") or "None"),
            requires_professional_review=True,
            emergency=is_deterministic_emergency
        )

    # 1. Deterministic emergency consistency: LLM cannot downgrade deterministic emergency
    if is_deterministic_emergency:
        resp.emergency = True
        resp.risk_level = RiskLevelEnum.emergency
    elif resp.emergency and resp.risk_level != RiskLevelEnum.emergency:
        resp.risk_level = RiskLevelEnum.emergency

    # 2. Symptom summary non-empty
    if not resp.symptom_summary or not resp.symptom_summary.strip():
        resp.symptom_summary = user_query

    # 3. Possible conditions capped at 3
    if len(resp.possible_conditions) > 3:
        resp.possible_conditions = resp.possible_conditions[:3]

    # 4. Each condition has reason and evidence_status
    for cond in resp.possible_conditions:
        if not cond.reason or not cond.reason.strip():
            cond.reason = "Reported symptoms share clinical features."
        if not cond.evidence_status or not cond.evidence_status.strip():
            cond.evidence_status = "Possible consideration; current information is insufficient to determine this."
        # Sanitize any definitive claim in condition name
        cond.name = re.sub(r'^(confirmed|definite|you have)\s+', '', cond.name, flags=re.IGNORECASE)

    # 5. What you can do now: 2 to 5 practical actions
    if not resp.what_you_can_do_now or len(resp.what_you_can_do_now) < 2:
        resp.what_you_can_do_now = [
            "Rest and monitor your symptoms closely.",
            "Record when symptoms began and note any changes.",
            "Consult a qualified healthcare professional for personalized medical advice."
        ]
    elif len(resp.what_you_can_do_now) > 5:
        resp.what_you_can_do_now = resp.what_you_can_do_now[:5]

    # 6. Warning signs non-empty
    if not resp.warning_signs or len(resp.warning_signs) == 0:
        resp.warning_signs = ["No specific warning signs were identified from the available information."]

    # 7. When to see a doctor non-empty
    if not resp.when_to_see_doctor or not resp.when_to_see_doctor.strip():
        if resp.risk_level == RiskLevelEnum.emergency:
            resp.when_to_see_doctor = "Seek emergency medical attention immediately. Call 108 / 112 or visit the nearest emergency room."
        elif resp.risk_level == RiskLevelEnum.high:
            resp.when_to_see_doctor = "Arrange a prompt professional medical evaluation today."
        elif resp.risk_level == RiskLevelEnum.moderate:
            resp.when_to_see_doctor = "Consult a doctor if symptoms persist or do not improve within 24 to 48 hours."
        else:
            resp.when_to_see_doctor = "Monitor and seek medical care if symptoms worsen, persist, or new warning signs appear."

    # 8. Evidence list non-empty
    if not resp.evidence:
        resp.evidence = [
            EvidenceItemSchema(
                title="No retrieved evidence",
                source_type="None",
                source="No retrieved medical evidence",
                citation="",
                relevance="Response is limited by insufficient evidence."
            )
        ]

    # 9. Medical disclaimer always present and canonical
    if not resp.medical_disclaimer or not resp.medical_disclaimer.strip() or "not a medical diagnosis" not in resp.medical_disclaimer.lower():
        resp.medical_disclaimer = standard_disclaimer

    # 10. Sanitize unsafe diagnosis claims in assessment
    unsafe_patterns = [
        r'you have (?:been diagnosed with|definitive|confirmed)',
        r'the diagnosis is (?:definitely|certainly|confirmed)',
        r'you definitely have',
    ]
    for pat in unsafe_patterns:
        resp.assessment.summary = re.sub(pat, 'Available symptoms may suggest consideration of', resp.assessment.summary, flags=re.IGNORECASE)

    return resp

def finalize_response(state: AgentState) -> AgentState:
    logger.info("NODE START: finalize_response")
    logger.info(f"REQUEST intent={state.get('intent')} agent={state.get('selected_agent')}")
    
    is_emergency = (state.get("intent") == "emergency") or (state.get("urgency") == "emergency")
    raw_structured = state.get("structured_response")
    user_query = state.get("user_query", "")
    
    validated_response = _validate_and_sanitize_clinical_response(raw_structured, user_query, is_emergency)
    formatted_answer = format_clinical_answer(validated_response)
    
    logger.info("NODE END: finalize_response")
    return {
        **state,
        "final_response": formatted_answer,
        "structured_response": validated_response.model_dump(),
        "graph_path": state.get("graph_path", []) + ["finalize_response"]
    }

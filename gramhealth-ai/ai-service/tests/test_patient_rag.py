import pytest
import tempfile
import uuid
from unittest.mock import patch, MagicMock

from patient.models import PatientContext, PatientRecord
from patient.rag import PatientRAGService
from patient.ingestion import ingest_patient_record
from api.agent_routes import AgentQueryRequest
from orchestrator import multi_agent_graph
from orchestrator.router import RouteClassification
from orchestrator.state import AgentState

@pytest.fixture(scope="module")
def temp_chroma_db():
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as temp_dir:
        with patch('rag.config.settings.settings.vector_db_path', temp_dir):
            with patch('rag.config.settings.settings.embedding_provider', 'local'):
                yield temp_dir

@pytest.fixture(scope="module")
def patient_rag_service(temp_chroma_db):
    service = PatientRAGService()
    
    # Insert PATIENT_001
    p1_records = [
        PatientRecord(
            patient_id="PATIENT_001",
            record_id="CONS_001",
            record_type="consultation",
            record_date="2026-08-01",
            text="PATIENT_001 presented with persistent high fever (39.5 C), severe joint pain, and mild rash. Suspected dengue.",
            source="Dr. Smith"
        ),
        PatientRecord(
            patient_id="PATIENT_001",
            record_id="LAB_001",
            record_type="lab_report",
            record_date="2026-08-02",
            text="PATIENT_001 CBC Report: Platelet count is critically low at 80,000 /mcL.",
            source="Central Lab"
        )
    ]
    
    # Insert PATIENT_002
    p2_records = [
        PatientRecord(
            patient_id="PATIENT_002",
            record_id="CONS_003",
            record_type="consultation",
            record_date="2026-07-15",
            text="PATIENT_002 reported chronic mild headaches and occasional dizziness.",
            source="Dr. Jones"
        )
    ]
    
    chunks = []
    for r in p1_records + p2_records:
        chunks.extend(ingest_patient_record(r))
        
    service.insert_chunks(chunks)
    service.relevance_filter.threshold = 999.0  # Accept all chunks regardless of distance for these tests
    return service


def test_missing_trusted_patient_identity_causes_safe_failure(patient_rag_service):
    # Missing patient context must trigger ValueError in PatientRAGService.query()
    with pytest.raises(ValueError, match="trusted patient identity is required"):
        patient_rag_service.query("symptoms", PatientContext(patient_id=""))

    with pytest.raises(ValueError, match="trusted patient identity is required"):
        patient_rag_service.query("symptoms", None)

def test_patient_isolation_patient_001(patient_rag_service):
    # Query with PATIENT_001 context
    ctx = PatientContext(patient_id="PATIENT_001")
    # Even if query asks about PATIENT_002, the filter should block it
    results = patient_rag_service.query("PATIENT_002", ctx)
    
    assert len(results) > 0
    for r in results:
        assert r["patient_id"] == "PATIENT_001"
        assert "PATIENT_002" not in r["text"]

def test_patient_isolation_patient_002(patient_rag_service):
    # Query with PATIENT_002 context
    ctx = PatientContext(patient_id="PATIENT_002")
    results = patient_rag_service.query("dengue fever", ctx)
    
    assert len(results) > 0
    for r in results:
        assert r["patient_id"] == "PATIENT_002"
        assert "PATIENT_001" not in r["text"]

def test_same_query_different_patient(patient_rag_service):
    query = "What did the doctor say in my last consultation?"
    
    res1 = patient_rag_service.query(query, PatientContext(patient_id="PATIENT_001"))
    res2 = patient_rag_service.query(query, PatientContext(patient_id="PATIENT_002"))
    
    assert len(res1) > 0
    assert len(res2) > 0
    assert res1[0]["patient_id"] == "PATIENT_001"
    assert res2[0]["patient_id"] == "PATIENT_002"
    assert res1[0]["chunk_id"] != res2[0]["chunk_id"]

@patch("orchestrator.nodes.router.classify")
def test_patient_only_query_routing(mock_classify, patient_rag_service):
    # 1. patient-only query
    mock_classify.return_value = RouteClassification(
        intent="clinical", urgency="normal", 
        requires_patient_context=True, requires_medical_knowledge=False, requires_structured_patient_lookup=False,
        selected_agent="patient_rag", routing_method="llm"
    )
    
    with patch("orchestrator.nodes.patient_rag", patient_rag_service):
        with patch("orchestrator.nodes.clinical_agent.reason", return_value={"answer": "mocked", "confidence": "high", "requires_professional_review": False}):
            state = multi_agent_graph.invoke({
                "user_query": "What were my symptoms yesterday?",
                "patient_context": {"patient_id": "PATIENT_001"}
            })
        
    assert "patient_rag" in state["graph_path"]
    assert "medical_rag" not in state["graph_path"]
    assert len(state["patient_evidence"]) > 0
    for ev in state["patient_evidence"]:
        assert ev["patient_id"] == "PATIENT_001"

@patch("orchestrator.nodes.router.classify")
def test_medical_only_query_routing(mock_classify, patient_rag_service):
    # 2. medical-only query
    mock_classify.return_value = RouteClassification(
        intent="clinical", urgency="normal", 
        requires_patient_context=False, requires_medical_knowledge=True, requires_structured_patient_lookup=False,
        selected_agent="medical_rag", routing_method="llm"
    )
    
    with patch("orchestrator.nodes.patient_rag", patient_rag_service):
        with patch("orchestrator.nodes.medical_rag") as mock_medical_rag:
            mock_medical_rag.vector_store.search_similarity.return_value = []
            mock_medical_rag.relevance_filter.filter_and_format.return_value = []
            
            with patch("orchestrator.nodes.clinical_agent.reason", return_value={"answer": "mocked", "confidence": "high", "requires_professional_review": False}):
                state = multi_agent_graph.invoke({
                    "user_query": "What are the guidelines for dengue?",
                    "patient_context": {"patient_id": "PATIENT_001"}
                })
            
    assert "medical_rag" in state["graph_path"]
    assert "patient_rag" not in state["graph_path"]
    # Medical-only query does not unnecessarily retrieve patient data
    assert not state.get("patient_evidence")

@patch("orchestrator.nodes.router.classify")
def test_hybrid_query_routing(mock_classify, patient_rag_service):
    # 3. hybrid query
    mock_classify.return_value = RouteClassification(
        intent="clinical", urgency="normal", 
        requires_patient_context=True, requires_medical_knowledge=True, requires_structured_patient_lookup=False,
        selected_agent="hybrid_rag", routing_method="llm"
    )
    
    with patch("orchestrator.nodes.patient_rag", patient_rag_service):
        with patch("orchestrator.nodes.medical_rag") as mock_medical_rag:
            mock_medical_rag.vector_store.search_similarity.return_value = []
            mock_medical_rag.relevance_filter.filter_and_format.return_value = []
            
            with patch("orchestrator.nodes.clinical_agent.reason", return_value={"answer": "mocked", "confidence": "high", "requires_professional_review": False}):
                state = multi_agent_graph.invoke({
                    "user_query": "Based on my fever, what do guidelines recommend?",
                    "patient_context": {"patient_id": "PATIENT_001"}
                })
            
    assert "hybrid_rag" in state["graph_path"]
    assert len(state["patient_evidence"]) > 0

def test_temporal_history_query(patient_rag_service):
    # 4. temporal/history query
    ctx = PatientContext(patient_id="PATIENT_001")
    # Query for historical lab report
    results = patient_rag_service.query("CBC report platelet count", ctx)
    
    assert len(results) > 0
    found_lab = any(r["record_type"] == "lab_report" for r in results)
    assert found_lab

@patch("orchestrator.nodes.router.classify")
def test_unsupported_route(mock_classify):
    mock_classify.return_value = RouteClassification(
        intent="unsupported", urgency="normal", 
        requires_patient_context=False, requires_medical_knowledge=False, requires_structured_patient_lookup=False,
        selected_agent="unsupported", routing_method="deterministic"
    )
    
    state = multi_agent_graph.invoke({
        "user_query": "Fix my car.",
        "patient_context": {"patient_id": "PATIENT_001"}
    })
    
    assert "unsupported" in state["graph_path"]
    assert state["final_response"] == "I cannot help with this request as it is outside my supported medical scope."

@patch("orchestrator.nodes.router.classify")
def test_emergency_priority(mock_classify):
    mock_classify.return_value = RouteClassification(
        intent="emergency", urgency="emergency", 
        requires_patient_context=True, requires_medical_knowledge=True, requires_structured_patient_lookup=False,
        selected_agent="emergency_agent", routing_method="deterministic"
    )
    
    mock_agent_response = MagicMock()
    mock_agent_response.response = "Go to ER"
    mock_agent_response.recommended_action = "Call 911"
    mock_agent_response.requires_professional_review = True
    
    with patch("orchestrator.nodes.emergency_agent.execute", return_value=mock_agent_response):
        state = multi_agent_graph.invoke({
            "user_query": "Severe chest pain",
            "patient_context": {"patient_id": "PATIENT_001"}
        })
    
    # Even if context is requested, emergency takes precedence
    assert "emergency_agent" in state["graph_path"]
    assert "patient_rag" not in state["graph_path"]
    assert "hybrid_rag" not in state["graph_path"]

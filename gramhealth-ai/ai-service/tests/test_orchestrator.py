import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from api.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "gramhealth-ai"
    assert "gemini_configured" in data

@patch("orchestrator.router.IntentRouter.classify")
@patch("agents.clinical_agent.ClinicalAgent.reason")
def test_clinical_routing(mock_reason, mock_classify):
    mock_class_response = MagicMock()
    mock_class_response.intent = "clinical"
    mock_class_response.urgency = "normal"
    mock_class_response.requires_patient_context = False
    mock_class_response.requires_medical_knowledge = False
    mock_class_response.requires_structured_patient_lookup = False
    mock_class_response.selected_agent = "clinical_agent"
    mock_class_response.routing_method = "llm"
    mock_classify.return_value = mock_class_response

    mock_reason.return_value = {
        "answer": "You have a fever. Rest.",
        "confidence": "high",
        "requires_professional_review": False,
        "grounded": False,
        "sources": [],
        "risk_level": "low",
        "recommended_next_step": "Rest."
    }

    response = client.post("/agent/query", json={"query": "I have a fever."})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "clinical"
    assert data["agent"] == "clinical_agent"
    assert data["answer"] == "You have a fever. Rest."
    assert data["grounded"] is False
    assert data["routing_method"] == "llm"
    assert data["graph_path"] == ["classify_request", "clinical_agent", "finalize_response"]

@patch("orchestrator.router.IntentRouter.classify")
@patch("agents.emergency_agent.EmergencyAgent.execute")
def test_emergency_routing(mock_execute, mock_classify):
    mock_class_response = MagicMock()
    mock_class_response.intent = "emergency"
    mock_class_response.urgency = "emergency"
    mock_class_response.requires_patient_context = False
    mock_class_response.requires_medical_knowledge = False
    mock_class_response.requires_structured_patient_lookup = False
    mock_class_response.selected_agent = "emergency_agent"
    mock_class_response.routing_method = "deterministic"
    mock_classify.return_value = mock_class_response

    mock_agent_response = MagicMock()
    mock_agent_response.response = "This is an emergency."
    mock_agent_response.recommended_action = "Call 911 immediately."
    mock_agent_response.requires_professional_review = True
    mock_execute.return_value = mock_agent_response

    response = client.post("/agent/query", json={"query": "severe chest pain"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "emergency"
    assert data["agent"] == "emergency_agent"
    assert "Call 911" in data["answer"]
    assert data["urgency"] == "emergency"
    assert data["routing_method"] == "deterministic"
    assert data["graph_path"] == ["classify_request", "emergency_agent", "finalize_response"]

@patch("orchestrator.router.IntentRouter.classify")
def test_unsupported_routing(mock_classify):
    mock_class_response = MagicMock()
    mock_class_response.intent = "unsupported"
    mock_class_response.urgency = "normal"
    mock_class_response.requires_patient_context = False
    mock_class_response.requires_medical_knowledge = False
    mock_class_response.requires_structured_patient_lookup = False
    mock_class_response.selected_agent = "unsupported"
    mock_class_response.routing_method = "deterministic"
    mock_classify.return_value = mock_class_response

    response = client.post("/agent/query", json={"query": "How do I fix a car?"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "unsupported"
    assert data["agent"] == "unsupported"
    assert "cannot help" in data["answer"]
    assert data["routing_method"] == "deterministic"
    assert data["graph_path"] == ["classify_request", "unsupported", "finalize_response"]

def test_malformed_request():
    response = client.post("/agent/query", json={"wrong_key": "text"})
    assert response.status_code == 422

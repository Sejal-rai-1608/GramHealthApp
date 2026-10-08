import os
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch

from rag.config.settings import settings, get_gemini_api_key, is_gemini_configured
from orchestrator.router import IntentRouter
from agents.clinical_agent import ClinicalAgent
from agents.emergency_agent import EmergencyAgent
from rag.pipeline import RAGPipeline
from api.main import app

client = TestClient(app)


class TestGeminiOptionalStartup:
    """
    Test suite verifying that the FastAPI service starts and operates
    safely when GEMINI_API_KEY is missing, empty, or configured.
    """

    def test_a_missing_gemini_key_fastapi_starts(self, monkeypatch):
        """Requirement 13.A: Missing GEMINI_API_KEY -> FastAPI starts and health check reports gemini_configured: false."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
        monkeypatch.setattr(settings, "gemini_api_key", None)

        assert not is_gemini_configured()
        assert get_gemini_api_key() is None

        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "gramhealth-ai"
        assert data["gemini_configured"] is False

    def test_b_valid_gemini_key_initializes(self, monkeypatch):
        """Requirement 13.B: Valid GEMINI_API_KEY -> Gemini initializes and is reported as configured."""
        dummy_key = "AIzaSyFakeKeyForTesting1234567890"
        monkeypatch.setenv("GEMINI_API_KEY", dummy_key)
        monkeypatch.setattr(settings, "gemini_api_key", dummy_key)

        assert is_gemini_configured()
        assert get_gemini_api_key() == dummy_key

        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["gemini_configured"] is True

        # Verify lazy instantiation of LLM on agents
        router = IntentRouter()
        assert router.llm is not None

        clinical = ClinicalAgent()
        assert clinical.llm is not None

        emergency = EmergencyAgent()
        assert emergency.llm is not None

    def test_c_emergency_query_works_without_gemini(self, monkeypatch):
        """Requirement 13.C: Emergency deterministic routing and response work without Gemini."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
        monkeypatch.setattr(settings, "gemini_api_key", None)

        response = client.post("/agent/query", json={"query": "I have severe chest pain and difficulty breathing"})
        assert response.status_code == 200
        data = response.json()
        assert data["intent"] == "emergency"
        assert data["agent"] == "emergency_agent"
        assert data["urgency"] == "emergency"
        assert data["routing_method"] == "deterministic"
        assert "911" in data["answer"]
        assert data["requires_professional_review"] is True
        assert data["graph_path"] == ["classify_request", "emergency_agent", "finalize_response"]

    def test_d_unsupported_query_works_without_gemini(self, monkeypatch):
        """Requirement 13.D: Unsupported query works without Gemini."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
        monkeypatch.setattr(settings, "gemini_api_key", None)

        response = client.post("/agent/query", json={"query": "How do I repair a car engine?"})
        assert response.status_code == 200
        data = response.json()
        assert data["intent"] == "unsupported"
        assert data["agent"] == "unsupported"
        assert data["routing_method"] == "deterministic"
        assert "cannot help" in data["answer"].lower() or "outside" in data["answer"].lower()
        assert data["graph_path"] == ["classify_request", "unsupported", "finalize_response"]

    def test_e_gemini_dependent_reasoning_returns_controlled_state_without_gemini(self, monkeypatch):
        """Requirement 13.E: Gemini-dependent reasoning returns a controlled error/state when Gemini is unavailable."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
        monkeypatch.setattr(settings, "gemini_api_key", None)

        response = client.post("/agent/query", json={"query": "I have a mild fever and persistent headache"})
        assert response.status_code == 200
        data = response.json()
        assert data["agent"] == "clinical_agent"
        assert data["intent"] == "clinical"
        assert data["confidence"] == "low"
        assert data["requires_professional_review"] is True
        assert "unavailable" in data["answer"].lower()
        assert data["error"] == "LLM_UNAVAILABLE"

    def test_medical_rag_retrieval_independent_of_gemini(self, monkeypatch):
        """Requirement 10: Medical RAG retrieval remains independently functional without Gemini."""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
        monkeypatch.setattr(settings, "gemini_api_key", None)

        pipeline = RAGPipeline()
        # Test retrieve method works independently without requiring Gemini
        results = pipeline.retrieve("fever", top_k=5)
        assert isinstance(results, list)

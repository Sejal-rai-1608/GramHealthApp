import pytest
import os
import json
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from api.main import app

from rag.sync.service import MedicalKnowledgeSyncService
from rag.sync.registry import DocumentRegistry
from rag.pipeline import RAGPipeline

client = TestClient(app)

@pytest.fixture
def mock_registry():
    db_path = "test_registry.db"
    if os.path.exists(db_path):
        os.remove(db_path)
    registry = DocumentRegistry(db_path)
    yield registry
    if os.path.exists(db_path):
        os.remove(db_path)

@pytest.fixture
def sync_service(mock_registry):
    with patch("rag.sync.service.DocumentRegistry", return_value=mock_registry):
        service = MedicalKnowledgeSyncService("test_registry.db")
        yield service

@patch("rag.sync.discovery.who.WHODiscoveryAdapter.discover")
@patch("rag.sync.downloader.DocumentDownloader.download_and_hash")
@patch.object(RAGPipeline, "ingest")
def test_sync_new_document(mock_ingest, mock_download, mock_discover, sync_service):
    # Mock discovery
    mock_discover.return_value = [{
        "document_id": "WHO-123",
        "publisher": "WHO",
        "title": "Test Guideline",
        "source_url": "http://who.int/123",
        "document_url": "http://who.int/123.pdf",
        "publication_date": "2023-01-01"
    }]
    
    # Mock download and hash
    mock_download.return_value = ("fake_temp_path.pdf", "hash123")
    
    # Mock ingestion
    mock_ingest.return_value = ["chunk1", "chunk2"]
    
    results = sync_service.sync()
    
    assert results["discovered"] == 1
    assert results["new"] == 1
    assert results["updated"] == 0
    assert results["unchanged"] == 0
    assert results["failed"] == 0
    assert results["chunks_added"] == 2
    
    mock_ingest.assert_called_once()

@patch("rag.sync.discovery.who.WHODiscoveryAdapter.discover")
@patch("rag.sync.downloader.DocumentDownloader.download_and_hash")
@patch.object(RAGPipeline, "ingest")
def test_sync_unchanged_document(mock_ingest, mock_download, mock_discover, sync_service):
    # Pre-populate registry with existing document
    sync_service.registry.upsert_document({
        "document_id": "WHO-123",
        "content_hash": "hash123",
        "ingestion_status": "success",
        "chunk_count": 2
    })
    
    mock_discover.return_value = [{
        "document_id": "WHO-123",
        "publisher": "WHO",
        "title": "Test Guideline",
        "document_url": "http://who.int/123.pdf",
    }]
    mock_download.return_value = ("fake_temp_path.pdf", "hash123") # Same hash
    
    results = sync_service.sync()
    
    assert results["discovered"] == 1
    assert results["new"] == 0
    assert results["updated"] == 0
    assert results["unchanged"] == 1
    assert results["chunks_added"] == 0
    
    mock_ingest.assert_not_called()

@patch("rag.sync.discovery.who.WHODiscoveryAdapter.discover")
@patch("rag.sync.downloader.DocumentDownloader.download_and_hash")
@patch.object(RAGPipeline, "ingest")
def test_sync_updated_document(mock_ingest, mock_download, mock_discover, sync_service):
    # Pre-populate registry with existing document
    sync_service.registry.upsert_document({
        "document_id": "WHO-123",
        "content_hash": "old_hash",
        "ingestion_status": "success",
        "chunk_count": 2
    })
    
    mock_discover.return_value = [{
        "document_id": "WHO-123",
        "publisher": "WHO",
        "title": "Test Guideline",
        "document_url": "http://who.int/123.pdf",
    }]
    mock_download.return_value = ("fake_temp_path.pdf", "new_hash") # Different hash
    mock_ingest.return_value = ["chunk1", "chunk2", "chunk3"]
    
    results = sync_service.sync()
    
    assert results["discovered"] == 1
    assert results["new"] == 0
    assert results["updated"] == 1
    assert results["unchanged"] == 0
    assert results["chunks_added"] == 3
    
    mock_ingest.assert_called_once()

@patch("rag.sync.discovery.who.WHODiscoveryAdapter.discover")
@patch("rag.sync.downloader.DocumentDownloader.download_and_hash")
@patch.object(RAGPipeline, "ingest")
def test_sync_api_endpoints(mock_ingest, mock_download, mock_discover):
    app.dependency_overrides = {}
    
    # Mocking the dependency in the routes
    mock_discover.return_value = []
    
    response = client.post("/medical-kb/sync")
    assert response.status_code == 200
    data = response.json()
    assert "discovered" in data
    
    response_status = client.get("/medical-kb/status")
    assert response_status.status_code == 200
    assert "total_documents" in response_status.json()

# Test routing Isolation
@patch("orchestrator.router.IntentRouter.classify")
@patch("patient.rag.PatientRAGService.query")
@patch("rag.pipeline.RAGPipeline.query")
def test_medical_rag_routing(mock_med_query, mock_pat_query, mock_classify):
    mock_class_response = MagicMock()
    mock_class_response.intent = "clinical"
    mock_class_response.urgency = "normal"
    mock_class_response.requires_patient_context = False
    mock_class_response.requires_medical_knowledge = True
    mock_class_response.requires_structured_patient_lookup = False
    mock_class_response.selected_agent = "medical_rag"
    mock_class_response.routing_method = "llm"
    mock_classify.return_value = mock_class_response

    # Setup the mock vector store retrieval within the node
    with patch("rag.retrieval.vector_store.ChromaVectorStore.search_similarity") as mock_vs:
        mock_vs.return_value = []
        with patch("rag.retrieval.relevance.RelevanceFilter.filter_and_format") as mock_rf:
            mock_rf.return_value = []
            
            # Using patch inside the execute_medical_rag function is tricky from here, 
            # let's just test that the API responds and goes through the medical RAG path.
            # We already patched IntentRouter.
            with patch("agents.clinical_agent.ClinicalAgent.reason") as mock_reason:
                mock_reason.return_value = {"answer": "Medical info."}
                
                response = client.post("/agent/query", json={"query": "What are common warning signs of dengue?"})
                assert response.status_code == 200
                assert "medical_rag" in response.json()["graph_path"]
                assert "patient_rag" not in response.json()["graph_path"]

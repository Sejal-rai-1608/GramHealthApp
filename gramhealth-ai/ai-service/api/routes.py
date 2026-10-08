from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Depends
from fastapi.exceptions import RequestValidationError
from typing import Optional
import tempfile
import os
import uuid

from rag.pipeline import RAGPipeline
from rag.models.schemas import RAGQueryRequest, RAGResponse
from rag.sync.service import MedicalKnowledgeSyncService

router = APIRouter(prefix="/rag", tags=["RAG"])
sync_router = APIRouter(prefix="/medical-kb", tags=["Medical-KB"])

# Dependency to get pipeline (instantiating it once would be better for prod, 
# but this is fine for the prototype)
_pipeline_instance = None
def get_pipeline():
    global _pipeline_instance
    if _pipeline_instance is None:
        _pipeline_instance = RAGPipeline()
    return _pipeline_instance

@router.post("/query", response_model=RAGResponse, summary="Query Medical Knowledge Base", description="Retrieve answers and verified citations directly from the local Chroma vector store and generate a response using Gemini.")
async def query_rag(request: RAGQueryRequest, pipeline: RAGPipeline = Depends(get_pipeline)):
    if not request.query.strip():
        raise RequestValidationError("Query cannot be empty")
    
    return pipeline.query(request.query, top_k=request.top_k)

@router.post("/ingest", summary="Ingest Medical Documents", description="Upload PDFs, markdown, or text files. Chunks and embeddings are stored in ChromaDB.")
async def ingest_document(
    file: UploadFile = File(...),
    source_url: Optional[str] = Form(None),
    publisher: Optional[str] = Form(None),
    pipeline: RAGPipeline = Depends(get_pipeline)
):
    if not file.filename.lower().endswith(('.pdf', '.txt', '.md')):
        raise HTTPException(status_code=400, detail="Unsupported file format")

    # Save temp file
    temp_dir = tempfile.gettempdir()
    temp_path = os.path.join(temp_dir, f"{uuid.uuid4()}_{file.filename}")
    
    try:
        with open(temp_path, "wb") as f:
            f.write(await file.read())
            
        chunk_ids = pipeline.ingest(temp_path, source_url=source_url, publisher=publisher)
        return {"status": "success", "chunks_inserted": len(chunk_ids)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

_sync_service_instance = None
def get_sync_service():
    global _sync_service_instance
    if _sync_service_instance is None:
        _sync_service_instance = MedicalKnowledgeSyncService()
    return _sync_service_instance

@sync_router.post("/sync", summary="Synchronize Medical Knowledge Base", description="Automatically discovers and ingests new or updated medical documents from approved sources.")
async def sync_medical_kb(service: MedicalKnowledgeSyncService = Depends(get_sync_service)):
    try:
        results = service.sync()
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@sync_router.get("/status", summary="Medical Knowledge Base Sync Status", description="Get the status of the local medical knowledge base sync.")
async def sync_status(service: MedicalKnowledgeSyncService = Depends(get_sync_service)):
    try:
        return service.get_status()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

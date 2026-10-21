from fastapi import APIRouter, HTTPException, Depends
from typing import List
import logging
from patient.models import PatientRecord
from patient.ingestion import ingest_patient_record
from patient.rag import PatientRAGService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/patient", tags=["Patient"])

_patient_rag_service_instance = None
def get_patient_rag_service():
    global _patient_rag_service_instance
    if _patient_rag_service_instance is None:
        _patient_rag_service_instance = PatientRAGService()
    return _patient_rag_service_instance

@router.post("/ingest", summary="Ingest Patient Records", description="Ingest structured patient records into the patient vector store for personalized RAG.")
async def ingest_patient_records(
    records: List[PatientRecord],
    service: PatientRAGService = Depends(get_patient_rag_service)
):
    if not records:
        return {"status": "success", "chunks_inserted": 0, "message": "No records provided."}
        
    try:
        all_chunks = []
        for record in records:
            chunks = ingest_patient_record(record)
            all_chunks.extend(chunks)
            
        if not all_chunks:
            return {"status": "success", "chunks_inserted": 0, "message": "No chunks generated from records."}
            
        chunk_ids = service.insert_chunks(all_chunks)
        
        logger.info(f"Successfully ingested {len(records)} records resulting in {len(chunk_ids)} chunks.")
        return {
            "status": "success", 
            "records_processed": len(records),
            "chunks_inserted": len(chunk_ids)
        }
    except Exception as e:
        logger.error(f"Error ingesting patient records: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to ingest patient records: {str(e)}")

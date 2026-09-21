import uuid
from typing import List
from langchain_core.documents import Document
from rag.chunking.splitter import chunk_documents
from .models import PatientRecord, PatientRecordChunk

def ingest_patient_record(record: PatientRecord, chunk_size: int = 1000, chunk_overlap: int = 200) -> List[PatientRecordChunk]:
    """
    Chunks a patient record for vector storage.
    Ensures patient_id and longitudinal metadata is preserved.
    """
    doc = Document(
        page_content=record.text,
        metadata={
            "patient_id": record.patient_id,
            "record_id": record.record_id,
            "record_type": record.record_type,
            "record_date": record.record_date,
            "source": record.source or "unknown",
            "collection": "patient_records"
        }
    )
    
    # We can reuse the generic chunking logic
    chunks = chunk_documents([doc], chunk_size=chunk_size, chunk_overlap=chunk_overlap)
    
    # Map back to our strict Pydantic model for safety
    patient_chunks = []
    for chunk in chunks:
        patient_chunks.append(
            PatientRecordChunk(
                chunk_id=chunk.metadata["chunk_id"],
                patient_id=chunk.metadata["patient_id"],
                record_id=chunk.metadata["record_id"],
                record_type=chunk.metadata["record_type"],
                record_date=chunk.metadata["record_date"],
                source=chunk.metadata["source"],
                text=chunk.page_content
            )
        )
        
    return patient_chunks

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List

class PatientContext(BaseModel):
    """Secure trusted patient context provided by the backend."""
    patient_id: str

class PatientRecord(BaseModel):
    """DTO for unstructured patient records (consultations, notes, reports)."""
    patient_id: str
    record_id: str
    record_type: str # 'consultation', 'lab_report', 'prescription', 'imaging', 'diagnosis', 'note', 'vital'
    record_date: str # ISO format 'YYYY-MM-DD'
    text: str
    source: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)

class PatientRecordChunk(BaseModel):
    """Represents a chunk of a patient record for the vector store."""
    chunk_id: str
    patient_id: str
    record_id: str
    record_type: str
    record_date: str
    text: str
    source: Optional[str] = None
    
class StructuredPatientFact(BaseModel):
    """DTO for exact structured information lookup (latest lab value, diagnosis, etc.)."""
    patient_id: str
    fact_type: str # 'hemoglobin', 'platelet_count', 'blood_pressure', 'diagnosis'
    fact_value: str
    date_recorded: str
    source: Optional[str] = None

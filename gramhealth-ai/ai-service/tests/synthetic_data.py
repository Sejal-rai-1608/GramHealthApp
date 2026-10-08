from patient.models import PatientRecord
from patient.ingestion import ingest_patient_record
from patient.rag import PatientRAGService

def load_synthetic_data():
    service = PatientRAGService()
    
    # PATIENT_001
    p1_records = [
        PatientRecord(
            patient_id="PATIENT_001",
            record_id="CONS_001",
            record_type="consultation",
            record_date="2026-08-01",
            text="Patient presented with persistent high fever (39.5 C), severe joint pain, and mild rash. Suspected dengue. Ordered CBC.",
            source="Dr. Smith"
        ),
        PatientRecord(
            patient_id="PATIENT_001",
            record_id="LAB_001",
            record_type="lab_report",
            record_date="2026-08-02",
            text="CBC Report: Platelet count is critically low at 80,000 /mcL. Hematocrit elevated. Consistent with dengue fever progression.",
            source="Central Lab"
        ),
        PatientRecord(
            patient_id="PATIENT_001",
            record_id="CONS_002",
            record_type="consultation",
            record_date="2026-08-10",
            text="Patient recovering. Platelets rising. Fever subsided. Advised continued rest and hydration.",
            source="Dr. Smith"
        )
    ]
    
    # PATIENT_002
    p2_records = [
        PatientRecord(
            patient_id="PATIENT_002",
            record_id="CONS_003",
            record_type="consultation",
            record_date="2026-07-15",
            text="Patient reported chronic mild headaches and occasional dizziness. Blood pressure normal. Prescribed mild pain relievers.",
            source="Dr. Jones"
        )
    ]
    
    chunks = []
    for r in p1_records + p2_records:
        chunks.extend(ingest_patient_record(r))
        
    service.insert_chunks(chunks)
    return chunks

if __name__ == "__main__":
    print("Loading synthetic patient data...")
    load_synthetic_data()
    print("Done.")

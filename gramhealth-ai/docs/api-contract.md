# GramHealth AI API Contract

## Base URL
`http://127.0.0.1:8000`

## 1. GET /health

Purpose: Check the health status of the AI service.

Request: `GET /health`

Response:
```json
{
  "status": "healthy",
  "service": "gramhealth-ai"
}
```

## 2. POST /agent/query

Purpose: Process a medical query through the multi-agent AI orchestrator.

Request:
```json
{
  "query": "I have fever and headache. What could this mean?",
  "patient_id": "P123"
}
```
*Note: The `patient_id` represents the trusted authenticated patient identity coming from the Node.js backend. The production patient identity should be resolved by the trusted backend/authentication layer. Do not use an arbitrary frontend `patient_id` as authorization.*

Response:
```json
{
  "query": "I have fever and headache. What could this mean?",
  "intent": "clinical",
  "agent": "clinical_agent",
  "answer": "Fever and headache are common symptoms...",
  "grounded": false,
  "confidence": "high",
  "urgency": "normal",
  "requires_professional_review": true,
  "evidence": {
    "patient": [],
    "medical": []
  },
  "sources": [],
  "routing_method": "llm",
  "graph_path": ["classify_request", "clinical_agent", "finalize_response"]
}
```

Allowed conceptual values:
- `intent`: `clinical`, `emergency`, `unsupported` (or similar identified by the routing logic)
- `routing_method`: `deterministic`, `llm`
- `urgency`: `normal`, `urgent`, `emergency`

*Evidence Structure: Patient evidence and medical evidence are clearly distinguishable in the `evidence` object.*

## 3. POST /rag/query

Purpose: Directly queries the Medical Knowledge RAG. Retrieve answers and verified citations directly from the local Chroma vector store and generate a response using Gemini.

Request:
```json
{
  "query": "What are the symptoms of malaria?",
  "top_k": 3
}
```

Response: Contains the `answer`, `sources`/citations, and `grounding` flag indicating if the answer was grounded in the retrieved context.

## 4. POST /rag/ingest

Purpose: Manual/admin ingestion of medical documents (PDFs, markdown, text files). Normal Medical Knowledge maintenance now uses the synchronization subsystem.

Request: `multipart/form-data` with `file`, optional `source_url`, optional `publisher`.

Response:
```json
{
  "status": "success",
  "chunks_inserted": 15
}
```

## 5. POST /medical-kb/sync

Purpose: Automatically discovers and ingests new or updated medical documents from approved sources (e.g. WHO).

Response: Returns results containing information about new/updated/unchanged/failed document synchronizations.

## 6. GET /medical-kb/status

Purpose: Get the status of the local medical knowledge base sync, including indexed document and sync information.

## 7. Errors

- `422 Unprocessable Entity`: Invalid query (e.g. empty query).
- `429 Too Many Requests`: AI service temporarily unavailable (e.g. resource exhausted / quota limits).
- `500 Internal Server Error`: An internal error occurred.

## 8. Patient Data Security

- PostgreSQL is the source of truth.
- Patient RAG is patient-scoped.
- Server-side filtering is enforced.
- Patient identity comes from trusted backend context.
- Cross-patient retrieval must not occur.

## 9. Example End-to-End Flows

### A. Patient-only
**Request:** "What did my previous consultation say about my fever?"
**Expected Route:** Patient RAG
**Important Response Fields:** `intent` (clinical), `agent` (patient_rag_agent), `evidence.patient` populated.

### B. Medical
**Request:** "What are common warning signs of dengue?"
**Expected Route:** Medical RAG
**Important Response Fields:** `intent` (clinical), `agent` (medical_rag_agent), `evidence.medical` populated.

### C. Hybrid
**Request:** "My fever has returned and my previous records showed low platelets. Is this concerning?"
**Expected Route:** Hybrid RAG
**Important Response Fields:** `intent` (clinical), `agent` (hybrid_rag_agent), both `evidence.patient` and `evidence.medical` populated.

### D. Emergency
**Request:** "I have severe chest pain and difficulty breathing."
**Expected Route:** Emergency Agent
**Important Response Fields:** `intent` (emergency), `agent` (emergency_agent), `urgency` (emergency).

### E. Unsupported
**Request:** "How do I repair a car engine?"
**Expected Route:** Unsupported
**Important Response Fields:** `intent` (unsupported), `agent` (unsupported_agent).

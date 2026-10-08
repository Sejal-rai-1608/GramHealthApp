# GramHealth AI — Team Handoff

## 1. Current Status
- AI subsystem implemented.
- 28 tests passing.
- AI service running through FastAPI.
- Medical RAG working.
- Patient RAG working.
- Hybrid routing implemented.
- Medical KB synchronization implemented.

COMPLETED:
- FastAPI AI service, RAG integrations, LangGraph routing, and Medical Knowledge Base synchronization.

PENDING INTEGRATION:
- Vilas PostgreSQL/backend integration.
- Sejal Flutter integration.
- Final end-to-end application flow.

## 2. Team Responsibilities

**SHUBHAM**
- AI service
- LangGraph orchestration
- agents
- Medical RAG
- Patient RAG retrieval layer
- Hybrid reasoning
- medical knowledge synchronization

**VILAS**
- Node.js backend
- PostgreSQL patient records
- authentication
- trusted patient identity
- communication between backend and AI service

**SEJAL**
- Flutter frontend
- query UI
- response rendering
- urgency/emergency display
- citations/evidence presentation

## 3. Current Architecture

```text
Flutter
↓
Node.js Backend
↓
AI Service
↓
Safety / Information Router
↓
Patient RAG / Medical RAG / Hybrid / Emergency
↓
Clinical Reasoning
↓
Final Response
```

PostgreSQL = patient source of truth
ChromaDB = retrieval index

## 4. Query Routing

- **Emergency** → Emergency Agent
- **Unsupported** → Unsupported
- **Patient context only** → Patient RAG
- **Medical knowledge only** → Medical RAG
- **Both** → Hybrid RAG
- **Neither** → Clinical Agent

Routing is based on information need, NOT merely phrases such as "according to the document".

## 5. Patient Data Contract

- PostgreSQL is authoritative.
- AI service should receive trusted patient context from Vilas/backend.
- Frontend must not be trusted to choose another patient's ID.
- Patient RAG applies server-side patient isolation.
- Synthetic PATIENT_001 and PATIENT_002 are test-only.

## 6. Medical Knowledge Synchronization

Approved source → discovery → download → hash → registry check → ingest if new/changed → ChromaDB Medical Knowledge index

- WHO is the initial approved source.
- SQLite is only the sync metadata registry.
- Manual `/rag/ingest` still exists.
- No arbitrary user URL becomes trusted knowledge.

## 7. API Integration Summary

| Endpoint | Used by | Purpose |
|----------|---------|---------|
| `/agent/query` | main AI interaction | Process medical query through AI orchestrator |
| `/rag/query` | direct Medical RAG testing/admin usage | Query Medical KB directly |
| `/rag/ingest` | manual/admin document ingestion | Manually ingest medical documents |
| `/medical-kb/sync` | trigger approved-source synchronization | Auto-sync medical KB |
| `/medical-kb/status` | sync/index status | Get sync status |
| `/health` | service health | Health check |

See [docs/api-contract.md](api-contract.md) for full schemas.

## 8. Integration Checklist

**Vilas**:
- expose authenticated patient identity
- map PostgreSQL records to AI service patient DTO/context
- call `/agent/query`
- handle AI service errors

**Sejal**:
- send query
- render answer
- render urgency
- render professional-review flag
- render evidence/citations when available

**Shubham**:
- maintain AI service
- update AI/API contract if contract changes

## 9. Local Development

```bash
cd ai-service
activate .venv
pip install -r requirements.txt
uvicorn api.main:app --reload
```

Testing:
```bash
python -m pytest tests/ -v
```

# GramHealth AI

An Adaptive AI Healthcare Platform using Multi-Agent Intelligence for Rural Healthcare.

## What it provides

- LangGraph multi-agent orchestration
- Medical Knowledge RAG
- Patient-aware RAG
- Hybrid evidence retrieval
- Emergency routing
- Automatic approved medical-source synchronization
- FastAPI API

## Architecture

```text
Flutter
↓
Backend/PostgreSQL
↓
AI Orchestrator
↓
Patient RAG / Medical RAG / Emergency
↓
Clinical Reasoning
↓
Response
```

PostgreSQL is the patient source of truth.
ChromaDB is used as the semantic retrieval layer.

## Run locally

```bash
cd ai-service
activate .venv
uvicorn api.main:app --reload
```

## Test

```bash
python -m pytest tests/ -v
```
Expected current validation: 28 tests passing.

## Main endpoints

| Endpoint | Method |
|---|---|
| `/health` | GET |
| `/agent/query` | POST |
| `/rag/query` | POST |
| `/rag/ingest` | POST |
| `/medical-kb/sync` | POST |
| `/medical-kb/status` | GET |

## Documentation

- [docs/team-handoff.md](docs/TEAM_HANDOFF.md)
- [docs/api-contract.md](docs/api-contract.md)
- [docs/architecture.md](docs/ARCHITECTURE.md)

## Status

Prototype / academic project.
Not clinically validated and not a substitute for professional medical care.

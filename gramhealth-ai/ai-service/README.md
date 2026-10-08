# GramHealth AI Orchestrator

**GramHealth — An Adaptive AI Healthcare Platform using Multi-Agent Intelligence for Rural Healthcare**

> **Status:** Academic / prototype implementation.
> This system is not a clinically validated medical device and does not replace professional medical care.

The GramHealth AI subsystem provides a **multi-agent medical intelligence layer** for the wider GramHealth healthcare platform.

It combines:

* LangGraph-based AI orchestration
* Clinical reasoning assistance
* Emergency-first safety handling
* Evidence-grounded Medical RAG
* Local semantic embeddings
* ChromaDB vector retrieval
* Gemini-based generation
* Deterministic and LLM-based intent routing
* Structured JSON responses
* Source/citation tracking
* Out-of-domain rejection
* Graph execution observability

The AI service is implemented in **Python + FastAPI** and is intended to integrate with the GramHealth **Node.js/Express backend** and **Flutter application**.

---

## Architecture

```text
                         GRAMHEALTH PLATFORM
                                |
                                v
                         Flutter Application
                                |
                                v
                       Node.js / Express Backend
                                |
                                v
                      Python FastAPI AI Service
                                |
                                v
                         POST /agent/query
                                |
                                v
                     ┌────────────────────────┐
                     │   LangGraph           │
                     │   AI Orchestrator     │
                     └───────────┬────────────┘
                                 |
                    ┌────────────┼────────────┐
                    |            |            |
                    v            v            v
              Clinical Agent  RAG Agent  Emergency Agent
                    |            |            |
                    |            v            |
                    |        ChromaDB          |
                    |     Medical Knowledge    |
                    |            |              |
                    └────────────┼──────────────┘
                                 |
                                 v
                         Structured Response
                                 |
                                 v
                        Node.js / Express
                                 |
                                 v
                          Flutter Application
```

The system also contains an **Unsupported** route for requests outside the supported medical domain.

---

# Multi-Agent Orchestration

The current orchestrator supports four routing outcomes:

```text
clinical
emergency
rag
unsupported
```

The routing layer uses two mechanisms.

### Deterministic routing

Obvious requests are handled without unnecessary LLM calls.

Examples include:

* severe chest pain
* difficulty breathing
* obvious emergency terminology
* "according to the document..."
* obvious medical knowledge-base questions
* clearly unsupported domains such as car repair

### LLM routing

When deterministic rules cannot confidently identify the intent, the system falls back to the Gemini-based structured router.

```text
User Query
    |
    v
Deterministic Routing
    |
    +---- obvious ----> Specialized Agent
    |
    +---- ambiguous --> LLM Router
                            |
                            v
                     Specialized Agent
```

The routing method is exposed in the response as:

```json
"routing_method": "deterministic"
```

or:

```json
"routing_method": "llm"
```

---

# Specialized Agents

## Clinical Agent

The Clinical Agent handles general medical and symptom-related questions.

Its purpose is to provide:

* cautious educational guidance
* symptom interpretation
* possible risk considerations
* recommendations to seek professional care when appropriate

It does **not** provide definitive diagnosis.

---

## Emergency Agent

The Emergency Agent handles potentially life-threatening situations.

Emergency detection has priority over normal routing.

For example:

```text
"I am having severe chest pain and difficulty breathing."
```

is routed directly to:

```text
Emergency Agent
```

The response prioritizes:

* immediate safety
* urgent medical attention
* emergency-service guidance
* professional evaluation

The emergency path can short-circuit normal agent execution.

Example graph path:

```json
[
  "classify_request",
  "emergency_agent",
  "finalize_response"
]
```

---

## RAG Agent

The RAG Agent is an adapter around the existing Medical RAG pipeline.

It provides:

* document ingestion
* PDF extraction
* semantic chunking
* local embeddings
* vector retrieval
* relevance filtering
* grounded generation
* citation propagation

The orchestrator does not reimplement the RAG pipeline; it delegates the query to the existing subsystem.

---

## Unsupported Agent

The Unsupported route safely handles requests outside the supported medical scope.

Example:

```text
"How do I repair a car engine?"
```

Expected behavior:

```json
{
  "intent": "unsupported",
  "agent": "unsupported",
  "grounded": false
}
```

The system does not attempt to generate unrelated answers.

---

# Medical RAG Pipeline

The current Medical RAG subsystem follows:

```text
Medical PDF
    |
    v
PyMuPDF Extraction
    |
    v
Semantic Chunking
    |
    v
Local Embeddings
    |
    v
ChromaDB
    |
    v
Semantic Retrieval
    |
    v
Relevance Filtering
    |
    v
Gemini Generation
    |
    v
Grounded Answer + Citations
```

### Embeddings

Embeddings are generated locally using:

```text
sentence-transformers/all-MiniLM-L6-v2
```

This removes the need for an embedding API and allows embedding generation to run locally.

### Vector Store

The current vector store is:

```text
ChromaDB
```

### Retrieval Metric

The current ChromaDB retrieval path uses **L2 distance**.

Lower distance means a better semantic match.

The relevance filter therefore uses:

```python
distance <= SIMILARITY_THRESHOLD
```

The current calibrated configuration uses:

```text
SIMILARITY_THRESHOLD=1.25
```

The retrieval window has also been expanded to:

```text
TOP_K=30
```

This is particularly important for table-heavy medical documents where the exact supporting evidence may rank lower than generic semantic matches.

---

# Grounded Generation

The RAG layer is explicitly evidence-first.

The model is not expected to invent an answer when sufficient supporting evidence cannot be retrieved.

For insufficient evidence:

```json
{
  "grounded": false,
  "confidence": "low",
  "requires_professional_review": true,
  "sources": []
}
```

For a grounded response:

```json
{
  "grounded": true,
  "confidence": "high",
  "sources": [...]
}
```

---

# Citation System

RAG citations are preserved as structured objects.

Each citation can contain:

```json
{
  "title": "...",
  "publisher": "...",
  "url": "...",
  "chunk_id": "..."
}
```

The citation mapping is performed server-side and is based on actually retrieved chunks.

This prevents the model from inventing arbitrary source references.

---

# Example RAG Query

Example medical question:

```text
According to the medical document, what temperature qualifies as fever in the Revised Jones criteria?
```

The system is capable of retrieving the relevant evidence from the indexed document and returning a grounded response with source metadata.

Example response shape:

```json
{
  "query": "According to the medical document, what temperature qualifies as fever in the Revised Jones criteria?",
  "answer": "...",
  "grounded": true,
  "confidence": "high",
  "requires_professional_review": true,
  "sources": [
    {
      "title": "...",
      "publisher": "World Health Organization",
      "url": "...",
      "chunk_id": "..."
    }
  ]
}
```

---

# Agent API

The main application-facing endpoint is:

```http
POST /agent/query
```

### Request

```json
{
  "query": "I have fever and headache. What could this mean?"
}
```

### Response

```json
{
  "query": "I have fever and headache. What could this mean?",
  "intent": "clinical",
  "agent": "clinical_agent",
  "answer": "...",
  "grounded": false,
  "confidence": "high",
  "urgency": "normal",
  "requires_professional_review": true,
  "sources": [],
  "routing_method": "llm",
  "graph_path": [
    "classify_request",
    "clinical_agent",
    "finalize_response"
  ]
}
```

---

# Response Fields

| Field                          | Purpose                                               |
| ------------------------------ | ----------------------------------------------------- |
| `query`                        | Original user query                                   |
| `intent`                       | `clinical`, `emergency`, `rag`, or `unsupported`      |
| `agent`                        | Agent selected by the orchestrator                    |
| `answer`                       | Final structured answer text                          |
| `grounded`                     | Whether the answer is supported by retrieved evidence |
| `confidence`                   | Confidence category                                   |
| `urgency`                      | `normal`, `urgent`, or `emergency`                    |
| `requires_professional_review` | Whether professional medical review is recommended    |
| `sources`                      | Structured RAG citation objects                       |
| `routing_method`               | `deterministic` or `llm`                              |
| `graph_path`                   | LangGraph execution trace                             |

---

# Available Endpoints

| Method | Endpoint       | Purpose                        |
| ------ | -------------- | ------------------------------ |
| `POST` | `/agent/query` | Main multi-agent AI entrypoint |
| `POST` | `/rag/query`   | Direct Medical RAG query       |
| `POST` | `/rag/ingest`  | Ingest a medical document      |
| `GET`  | `/health`      | Service health check           |

FastAPI also exposes the generated OpenAPI documentation.

---

# Swagger / OpenAPI

After starting the service:

```text
http://127.0.0.1:8000/docs
```

The current API exposes:

```text
RAG
├── POST /rag/query
└── POST /rag/ingest

Agent
└── POST /agent/query

Default
└── GET /health
```

---

# Environment Configuration

Create a `.env` file from the project's environment template.

The exact variable names should be taken from the current `settings.py` / `.env.example`.

Typical configuration includes:

```env
GEMINI_API_KEY="your-gemini-api-key"

VECTOR_DB_PATH=./chroma_db

TOP_K=30

SIMILARITY_THRESHOLD=1.25

CHUNK_SIZE=1000

CHUNK_OVERLAP=200

MAX_CONTEXT_TOKENS=15000

EMBEDDING_PROVIDER=local

LOCAL_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

CHROMA_COLLECTION=gramhealth_medical_rag_local

GEMINI_MODEL=gemini-3.6-flash
```

> Never commit the real `GEMINI_API_KEY` to Git.

The Gemini model is configuration-driven rather than hardcoded into the RAG pipeline.

---

# Local Setup

## 1. Enter the AI service

```bash
cd ai-service
```

## 2. Create a virtual environment

Windows PowerShell:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

## 3. Install dependencies

```bash
pip install -r requirements.txt
```

## 4. Configure environment variables

Create:

```text
.env
```

and provide the required Gemini configuration.

## 5. Start FastAPI

```bash
uvicorn api.main:app --reload
```

The service will run at:

```text
http://127.0.0.1:8000
```

---

# RAG Document Ingestion

A PDF can be ingested using:

```bash
curl -X POST "http://127.0.0.1:8000/rag/ingest" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/fever.pdf" \
  -F "publisher=World Health Organization" \
  -F "source_url=https://example.com/source"
```

A successful ingestion returns a response similar to:

```json
{
  "status": "success",
  "chunks_inserted": 284
}
```

---

# Direct RAG Query

```bash
curl -X POST "http://127.0.0.1:8000/rag/query" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What does the document say about fever in the Revised Jones criteria?",
    "top_k": 10,
    "filters": {}
  }'
```

---

# Multi-Agent Query

For application integration, use the orchestrator endpoint instead of directly calling individual agents.

```bash
curl -X POST "http://127.0.0.1:8000/agent/query" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "I have fever and headache. What could this mean?"
  }'
```

The orchestrator decides which specialized component should process the request.

---

# Observability

The LangGraph workflow records the execution path.

Example:

```json
"graph_path": [
  "classify_request",
  "rag_agent",
  "finalize_response"
]
```

Emergency example:

```json
"graph_path": [
  "classify_request",
  "emergency_agent",
  "finalize_response"
]
```

This makes the orchestration behavior inspectable during development, testing, and demonstrations.

---

# Validation Scenarios

The current implementation has been verified against these core scenarios.

## 1. Clinical

```text
I have fever and headache. What could this mean?
```

Expected:

```text
agent = clinical_agent
intent = clinical
```

---

## 2. Emergency

```text
I am having severe chest pain and difficulty breathing.
```

Expected:

```text
agent = emergency_agent
intent = emergency
urgency = emergency
routing_method = deterministic
```

The emergency path should prioritize immediate safety guidance.

---

## 3. RAG

```text
According to the medical document, what temperature qualifies as fever in the Revised Jones criteria?
```

Expected:

```text
agent = rag_agent
grounded = true
sources != []
```

---

## 4. Unsupported

```text
How do I repair a car engine?
```

Expected:

```text
intent = unsupported
agent = unsupported
grounded = false
```

---

# Testing

The current orchestrator test suite contains **7 passing tests** covering the main routing and graph behavior.

Run:

```bash
python -m pytest tests/test_orchestrator.py -v
```

For compilation checks:

```bash
python -m compileall agents orchestrator rag api
```

The tests cover areas including:

* clinical routing
* emergency routing
* RAG routing
* unsupported routing
* emergency priority
* graph execution
* structured response behavior

Live Gemini testing can be affected by Google API quota limits.

---

# Gemini API Quota

The system uses Gemini for cloud generation and LLM-based routing when deterministic routing is insufficient.

During development, the Google free-tier project quota has produced:

```text
429 RESOURCE_EXHAUSTED
```

when the daily request limit is exceeded.

This does not imply that the LangGraph architecture itself failed.

To minimize unnecessary API usage:

1. obvious emergency requests are handled deterministically
2. obvious RAG requests can be routed deterministically
3. obvious unsupported queries can be rejected deterministically
4. only ambiguous requests need LLM-based routing

---

# Safety Principles

GramHealth follows these principles:

### Emergency first

Potential emergencies receive priority over normal informational processing.

### No definitive diagnosis

The system provides educational and decision-support information rather than claiming to diagnose a patient.

### Grounded medical answers

Medical-document questions should be answered from retrieved evidence whenever possible.

### Evidence insufficiency

When adequate evidence cannot be retrieved, the system should not invent an answer.

### Professional review

Responses can explicitly indicate:

```text
requires_professional_review = true
```

### Out-of-domain rejection

Non-medical requests are rejected rather than answered using unrelated knowledge.

---

# Current Technology Stack

## AI Service

* Python
* FastAPI
* Pydantic
* LangGraph
* LangChain
* Google Gemini
* google-genai / LangChain Google GenAI integration
* PyMuPDF
* sentence-transformers
* ChromaDB

## Application Platform

* Flutter
* Node.js
* Express.js
* PostgreSQL / application-side local storage where applicable

## Development

* Git
* GitHub
* VS Code
* pytest
* Uvicorn

---

# Project Structure

The exact structure may evolve, but the AI service currently follows this separation:

```text
ai-service/
│
├── api/
│   ├── main.py
│   ├── routes.py
│   └── agent_routes.py
│
├── agents/
│   ├── base.py
│   ├── clinical_agent.py
│   ├── emergency_agent.py
│   └── rag_agent.py
│
├── orchestrator/
│   ├── state.py
│   ├── router.py
│   ├── nodes.py
│   ├── graph.py
│   └── __init__.py
│
├── rag/
│   ├── pipeline.py
│   ├── relevance.py
│   ├── embeddings.py
│   └── ...
│
├── tests/
│   └── test_orchestrator.py
│
├── requirements.txt
├── .env.example
└── README.md
```

Use the actual repository structure as the source of truth when files are added or reorganized.

---

# Integration with GramHealth

The intended production-facing flow is:

```text
Flutter
   |
   v
Node.js / Express
   |
   v
POST /agent/query
   |
   v
Python FastAPI
   |
   v
LangGraph Orchestrator
   |
   +---- Clinical
   |
   +---- Emergency
   |
   +---- RAG
   |
   +---- Unsupported
   |
   v
Structured AI Response
   |
   v
Node.js / Express
   |
   v
Flutter
```

The frontend and backend should depend on the **API response contract**, not on internal Python agent implementations.

For integration details, see the project's API contract documentation.

---

# Current Project State

## Implemented

* [x] FastAPI AI service
* [x] Medical PDF ingestion
* [x] Local embeddings
* [x] ChromaDB retrieval
* [x] RAG relevance filtering
* [x] Grounded generation
* [x] Server-side citations
* [x] LangGraph orchestrator
* [x] Clinical Agent
* [x] Emergency Agent
* [x] RAG Agent adapter
* [x] Unsupported route
* [x] Deterministic routing
* [x] LLM routing fallback
* [x] Emergency priority routing
* [x] Structured API response
* [x] `routing_method`
* [x] `graph_path`
* [x] OpenAPI / Swagger integration
* [x] Orchestrator tests

## Integration / Future Work

The broader GramHealth platform still includes integration work such as:

* Node.js ↔ AI service integration
* Flutter ↔ Node integration
* offline-first application workflows
* adaptive connectivity behavior
* synchronization workflows
* final end-to-end deployment

These should only be described as completed when they are verified in the current repository.

---

# Limitations

GramHealth is currently an **academic prototype**.

It should not be treated as:

* a replacement for a doctor
* a diagnostic authority
* a clinically validated medical device
* a guaranteed source of medical advice

Additional limitations include:

* Gemini API quota limitations
* dependency on the configured cloud model for generation
* local ChromaDB storage during development
* ongoing integration with the wider Flutter and Node.js platform

---

# Team

| Team Member    | Primary Area                                 |
| -------------- | -------------------------------------------- |
| Sejal Rai      | Flutter / Frontend                           |
| Shubham Sawant | AI Service / RAG / Multi-Agent Orchestration |
| Vilas Oza      | Node.js / Express Backend / Infrastructure   |
| Lokesh Rane    | Project Team Member                          |

---

# Documentation

Important project documentation should include:

```text
docs/
├── API_CONTRACTS.md
├── TEAM_HANDOFF.md
├── architecture.md
└── decisions.md
```

`API_CONTRACTS.md` defines the integration contract.

`TEAM_HANDOFF.md` explains what the Flutter and backend teams need to implement around the AI service.

---

# Summary

GramHealth's current AI subsystem is no longer only a standalone Medical RAG prototype.

It is now a **multi-agent medical AI orchestration layer** that:

```text
Receives a user request
        ↓
Classifies the request
        ↓
Prioritizes emergencies
        ↓
Routes to the appropriate specialized agent
        ↓
Retrieves medical evidence when required
        ↓
Generates a structured response
        ↓
Preserves citations and observability
        ↓
Returns a stable API response
```

The core goal is to provide **safe, traceable, evidence-aware AI assistance** that can serve as the intelligence layer of the broader GramHealth rural healthcare platform.

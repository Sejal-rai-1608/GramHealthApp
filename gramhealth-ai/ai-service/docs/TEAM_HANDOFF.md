## Product

**GramHealth — An Adaptive AI Healthcare Platform using Multi-Agent Intelligence for Rural Healthcare**

GramHealth is designed for rural healthcare environments where poor connectivity, limited healthcare infrastructure, and intermittent internet access can interrupt digital healthcare delivery.

The overall platform combines:

* Adaptive connectivity
* Offline-first healthcare workflows
* Cloud AI
* Multi-agent AI orchestration
* Medical Retrieval-Augmented Generation
* Emergency-first safety handling
* Intelligent synchronization
* Flutter mobile applications
* Node.js / Express backend

The AI subsystem is implemented in Python using FastAPI.

---

# CURRENT AI ARCHITECTURE

Current implemented architecture:

```text
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
LangGraph AI Orchestrator
        |
        +-------------------+
        |                   |
        v                   v
 Deterministic         LLM Router
 Safety / Intent       fallback
 Detection                 |
        |                  |
        +---------+--------+
                  |
        v
       Specialized Agent
                  |
       +----------+----------+-------------+
       |                     |             |
       v                     v             v
Clinical Agent          RAG Agent     Emergency Agent
       |                     |             |
       |                     v             |
       |                ChromaDB           |
       |             Medical Knowledge     |
       |                     |             |
       +----------+----------+-------------+
                  |
                  v
        Structured AI Response
                  |
                  v
        Node Backend / Flutter
```

There is also an `unsupported` route for requests outside the supported medical scope.

---

# CURRENT ROUTING MODEL

The orchestrator currently supports:

```text
clinical
emergency
rag
unsupported
```

Do NOT describe `general` as a current intent.

Routing currently supports two mechanisms:

```text
routing_method = deterministic
routing_method = llm
```

Deterministic routing is used for obvious cases such as:

* emergency symptoms
* obvious RAG/document questions
* obvious unsupported/out-of-domain queries

Ambiguous cases can fall through to the Gemini-based structured router.

---

# EMERGENCY PRIORITY

Emergency handling is safety-critical.

Emergency detection has priority over normal routing.

For an obvious emergency such as:

> "I am having severe chest pain and difficulty breathing."

the expected behavior is:

```text
classify_request
        ↓
emergency_agent
        ↓
finalize_response
```

The emergency agent should provide immediate safety-oriented guidance and recommend emergency medical assistance.

Do NOT describe the system as diagnosing the patient.

Do NOT claim clinical validation or production medical-device certification.

---

# CURRENT RAG SYSTEM

The existing Medical RAG subsystem is already implemented and integrated into the orchestrator.

Current components include:

* PDF ingestion
* document chunking
* local embeddings
* ChromaDB vector storage
* semantic retrieval
* relevance filtering
* Gemini-based grounded generation
* source/citation propagation
* out-of-domain rejection
* grounded-response checks

Current embedding model:

```text
sentence-transformers/all-MiniLM-L6-v2
```

Vector database:

```text
ChromaDB
```

The RAG agent is an adapter around the existing RAG pipeline.

Do NOT replace it with another RAG framework.

Do NOT claim that the orchestrator owns the retrieval implementation.

---

# IMPORTANT RAG BEHAVIOR

The RAG system must remain evidence-grounded.

If adequate evidence is not retrieved:

```text
grounded = false
```

and the system should refuse to invent an answer.

The system has already demonstrated this behavior for an out-of-domain query such as:

> "How do I repair a car engine?"

which correctly produces an unsupported/insufficient-evidence response instead of hallucinating a medical answer.

The RAG system also supports source citations containing structured metadata such as:

```text
title
publisher
url
chunk_id
```

Do not simplify citations to plain strings.

---

# CURRENT AGENT API

The primary integration endpoint is:

```http
POST /agent/query
```

Request:

```json
{
  "query": "I have fever and headache. What could this mean?"
}
```

Current response structure:

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

The final implementation also exposes the structured source objects for RAG responses.

Do not invent additional required response fields.

---

# CURRENT GRAPH OBSERVABILITY

The orchestrator tracks:

```text
routing_method
graph_path
```

Example:

```json
"routing_method": "deterministic",
"graph_path": [
  "classify_request",
  "emergency_agent",
  "finalize_response"
]
```

This exists specifically so developers and judges can see how the request moved through the system.

---

# CURRENT FASTAPI SURFACE

The AI service currently exposes:

```text
POST /rag/query
POST /rag/ingest
POST /agent/query
GET  /health
```

The Swagger/OpenAPI UI is available through FastAPI.

Document this accurately.

---

# CURRENT TESTING STATUS

The orchestrator test suite currently contains 7 passing tests.

Document:

```text
7 orchestrator tests passing
```

The tests cover the current routing/orchestration behavior, including:

* clinical routing
* emergency routing
* RAG routing
* unsupported routing
* emergency priority behavior
* graph execution
* response contract behavior

Do NOT claim that every live Gemini scenario has been exhaustively tested if quota limitations prevented that.

---

# GEMINI / QUOTA REALITY

Gemini is used as the cloud generation/routing provider.

The free Google quota has already caused `429 RESOURCE_EXHAUSTED` errors during excessive live testing.

Do NOT hide this fact.

Explain that:

* the system architecture works
* deterministic routing reduces unnecessary model usage
* tests can be mocked/offline
* live Gemini testing may be restricted by free-tier quotas
* API keys must never be committed

Do NOT change the currently configured model simply for documentation purposes.

Do NOT introduce another LLM provider.

---

# IMPORTANT CURRENT LIMITATION

There is currently a startup/import issue that must be clearly documented as a known engineering issue if it still exists in the repository:

```text
ImportError: attempted relative import beyond top-level package
```

The reported failing chain was:

```text
api.main
  -> api.routes
      -> ..rag.pipeline
```

Do NOT pretend the service is fully production-ready if this remains unresolved.

Instead:

1. Inspect the current repository.
2. Determine whether the issue still exists.
3. If it exists, add a clearly marked "Known Issue / Local Setup" section.
4. Do NOT silently change application architecture merely to hide the problem.

---

# PART 2 — README.md

Rewrite the existing README from scratch around the **current implementation**.

The README should contain:

## 1. Project title

Use:

# GramHealth

Subtitle:

> An Adaptive AI Healthcare Platform using Multi-Agent Intelligence for Rural Healthcare

---

## 2. Project Overview

Explain:

* rural healthcare challenge
* unreliable connectivity
* offline-first vision
* adaptive AI
* multi-agent architecture
* evidence-grounded medical RAG

Keep this focused on the actual project rather than generic AI marketing.

---

## 3. Problem

Explain:

* rural connectivity limitations
* limited access to healthcare professionals
* interruptions in telemedicine
* cloud-dependent AI limitations
* need for safe AI assistance

---

## 4. Solution

Explain GramHealth as an integrated platform consisting of:

* Flutter application
* Node.js / Express backend
* Python AI service
* LangGraph orchestration
* clinical agent
* emergency agent
* RAG agent
* unsupported safety boundary
* adaptive/offline direction

Clearly distinguish:

### Implemented now

from

### Planned / future platform capabilities

Do NOT present future components as already finished.

---

## 5. AI Architecture

Include a clean Mermaid architecture diagram.

Use the CURRENT architecture, not the old planned structure.

Show:

```text
Flutter
↓
Node/Express
↓
FastAPI AI Service
↓
LangGraph Orchestrator
↓
Clinical / Emergency / RAG / Unsupported
↓
Structured response
```

Show ChromaDB and medical knowledge under the RAG path.

---

## 6. Multi-Agent Intelligence

Explain each current agent:

### Clinical Agent

Handles general medical/clinical questions cautiously.

Does not provide definitive diagnosis.

### Emergency Agent

Handles high-risk situations and prioritizes immediate safety.

Emergency routing overrides normal routing.

### RAG Agent

Uses the existing medical RAG pipeline to answer questions using approved knowledge sources and citations.

### Unsupported Agent

Rejects non-medical or unsupported-domain questions.

---

## 7. Routing

Explain:

```text
deterministic routing
        ↓
if obvious → direct specialized route

otherwise
        ↓
LLM structured router
```

Include:

```text
clinical
emergency
rag
unsupported
```

Do not call unsupported "general".

---

## 8. Medical RAG

Document:

```text
PDF
 ↓
Extraction
 ↓
Chunking
 ↓
Local Embedding
 ↓
ChromaDB
 ↓
Semantic Retrieval
 ↓
Relevance Filtering
 ↓
Gemini Grounded Generation
 ↓
Citations
```

Mention:

```text
Embedding model:
sentence-transformers/all-MiniLM-L6-v2
```

and:

```text
Vector store:
ChromaDB
```

---

## 9. Safety / Grounding

Explain:

* evidence-first answers
* refusal when evidence is insufficient
* emergency priority
* professional review flag
* no definitive diagnosis
* out-of-domain rejection
* source citations

---

## 10. API

Give a concise `/agent/query` example.

Reference the existing API contract document rather than duplicating every detail.

Example:

```bash
curl -X POST http://127.0.0.1:8000/agent/query \
  -H "Content-Type: application/json" \
  -d '{"query":"I have fever and headache. What could this mean?"}'
```

---

## 11. API Endpoints

Document:

| Endpoint          | Purpose                        |
| ----------------- | ------------------------------ |
| POST /agent/query | Main multi-agent AI entrypoint |
| POST /rag/query   | Direct RAG query               |
| POST /rag/ingest  | Add medical document           |
| GET /health       | AI service health              |

---

## 12. Tech Stack

Use the ACTUAL current stack:

* Python
* FastAPI
* Pydantic
* LangGraph
* LangChain / Google GenAI integration
* Gemini API
* sentence-transformers
* ChromaDB
* PyMuPDF
* pytest
* Flutter
* Node.js
* Express.js
* PostgreSQL / SQLite where applicable in the wider platform

Do not list technologies merely because they appeared in old plans.

---

## 13. Project Structure

Inspect the actual repository and generate a structure that reflects the CURRENT files.

Do not copy the old hypothetical structure.

---

## 14. Running the AI Service

Document the current setup.

Include:

```bash
cd ai-service
python -m venv .venv
```

activation instructions appropriate for Windows PowerShell.

Then:

```bash
pip install -r requirements.txt
```

and:

```bash
uvicorn api.main:app --reload
```

Also mention environment configuration.

Never print or commit real API keys.

---

## 15. Testing

Document the actual available commands.

At minimum:

```bash
python -m pytest tests/test_orchestrator.py -v
python -m compileall agents orchestrator rag api
```

Do not fabricate test output.

---

## 16. Current Validation

Include the known validated scenarios:

### Clinical

```text
"I have fever and headache. What could this mean?"
```

→ clinical agent

### Emergency

```text
"I am having severe chest pain and difficulty breathing."
```

→ emergency agent

### RAG

```text
"According to the medical document, what temperature qualifies as fever in the Revised Jones criteria?"
```

→ RAG agent

### Unsupported

```text
"How do I repair a car engine?"
```

→ unsupported

---

## 17. Limitations

Clearly distinguish:

* academic prototype
* not a clinically validated medical device
* Gemini quota limitations
* current local-development dependency
* offline/adaptive platform components that are still under integration if they are not yet complete

---

## 18. Team

Use the actual project team:

* Sejal Rai — Flutter / frontend
* Shubham Sawant — AI subsystem
* Vilas Oza — Node.js / backend / infrastructure
* Lokesh Rane — project team member

Do not invent responsibilities that are not supported by the repository.

---

# PART 3 — CREATE docs/TEAM_HANDOFF.md

This is NOT another API contract.

It should be a practical handoff document written specifically for:

## Sejal — Flutter

## Vilas — Node.js / Backend

Its job is to answer:

> "What does Shubham's AI subsystem already provide, what do I need to integrate, what should I build, and what should I not touch?"

---

# TEAM HANDOFF STRUCTURE

Create these sections:

# GramHealth Team Handoff

## 1. Purpose

Explain that the AI subsystem is now a working service and the remaining work is cross-layer integration.

---

## 2. Who Owns What

Use this ownership model:

| Area                      | Owner                     |
| ------------------------- | ------------------------- |
| Python AI subsystem       | Shubham                   |
| LangGraph orchestration   | Shubham                   |
| Clinical Agent            | Shubham                   |
| Emergency Agent           | Shubham                   |
| RAG pipeline              | Shubham                   |
| AI prompts/models         | Shubham                   |
| AI safety logic           | Shubham + clinical review |
| Node/Express backend      | Vilas                     |
| Backend DB/auth           | Vilas                     |
| Backend → AI integration  | Vilas                     |
| Deployment/secrets/DevOps | Vilas                     |
| Flutter UI/UX             | Sejal                     |
| Flutter state management  | Sejal                     |
| Flutter API client        | Sejal                     |
| Emergency UI              | Sejal                     |
| Source/citation UI        | Sejal                     |
| Offline UI/queue behavior | Sejal                     |

Use clear language:

> Do not modify another owner's core implementation without agreement.

---

# 3. Current System Boundary

Show:

```text
SEJAL
Flutter
   ↓
VILAS
Node / Express
   ↓
SHUBHAM
Python / FastAPI AI Service
   ↓
LangGraph
   ↓
Agents + RAG
```

Explain the boundary between each layer.

---

# 4. What Shubham's AI Service Already Provides

Explain that Vilas and Sejal do NOT need to rebuild:

* intent routing
* emergency agent
* clinical agent
* RAG retrieval
* ChromaDB
* medical embeddings
* grounded response generation
* citation mapping
* unsupported-domain rejection
* graph orchestration

They consume the service through the API.

---

# 5. VILAS — YOUR RESPONSIBILITIES

Create a dedicated section.

Vilas needs to:

### Backend integration

Build the Node/Express integration to:

```text
Flutter
 ↓
Node API
 ↓
POST /agent/query
 ↓
AI service
 ↓
Node
 ↓
Flutter
```

### Request forwarding

Forward the appropriate user query to the AI service.

Do not recreate AI routing rules in Node.

### Response handling

Preserve:

```text
intent
agent
answer
grounded
confidence
urgency
requires_professional_review
sources
routing_method
graph_path
```

Do not throw away fields.

### Error handling

Map AI-service errors into stable backend errors.

Do not leak stack traces.

### Secrets

Keep Gemini/API secrets server-side.

Flutter must never receive the Gemini API key.

### Deployment

Ensure:

* AI service reachable
* Node backend knows AI service URL
* environment variables documented
* CORS/network configuration works
* health checks exist

### Backend tests

Create at least:

```text
AI service reachable
clinical response forwarding
emergency response forwarding
RAG response forwarding
unsupported response forwarding
AI error handling
```

---

# 6. SEJAL — YOUR RESPONSIBILITIES

Create a dedicated section.

Sejal consumes the response through the Node backend.

### Clinical UI

Render:

* answer
* confidence
* professional review indicator
* loading state
* error state

Do not expose internal graph state to normal users unless demo/debug mode requires it.

### Emergency UI

When:

```text
urgency == "emergency"
```

display a clearly visible emergency experience.

The UI should emphasize immediate action rather than a long AI explanation.

### RAG UI

When:

```text
agent == "rag_agent"
```

show:

* answer
* source/citation cards
* publisher
* source link
* grounded status

### Unsupported UI

For:

```text
intent == "unsupported"
```

show the safe refusal normally.

Do not present it as an application failure.

### Loading states

The AI request may take longer than normal API requests.

Provide:

```text
loading
success
error
```

states.

### Offline / poor network

Do not pretend cloud AI is available when disconnected.

Use the existing application's offline strategy and coordinate with Vilas.

---

# 7. WHAT NOT TO DO

### Sejal must NOT

* modify Python AI agents
* modify LangGraph routing
* modify ChromaDB
* change AI prompts
* add Gemini calls directly from Flutter
* store Gemini API keys in Flutter
* invent a second AI API

### Vilas must NOT

* rewrite LangGraph
* modify clinical prompts
* modify emergency rules
* modify RAG retrieval thresholds
* duplicate intent routing in Node
* create a second AI contract without agreement
* expose Gemini credentials

---

# 8. MAIN API FLOW

Explain one complete request.

Example:

```text
User:
"I am having severe chest pain and difficulty breathing."

Flutter
 ↓
Node
 ↓
POST /agent/query
 ↓
AI Orchestrator
 ↓
Emergency detection
 ↓
Emergency Agent
 ↓
Structured response
 ↓
Node
 ↓
Flutter Emergency UI
```

And RAG:

```text
User asks medical-document question
 ↓
Flutter
 ↓
Node
 ↓
POST /agent/query
 ↓
RAG Agent
 ↓
ChromaDB retrieval
 ↓
Grounded generation
 ↓
Citation mapping
 ↓
Node
 ↓
Flutter source cards
```

---

# 9. RESPONSE FIELD GUIDE

Create a table:

| Field                        | Meaning                    | Sejal use               | Vilas use         |
| ---------------------------- | -------------------------- | ----------------------- | ----------------- |
| query                        | Original request           | optional                | logging           |
| intent                       | selected intent            | UI decisions            | routing/analytics |
| agent                        | selected specialized agent | UI decisions            | logging           |
| answer                       | final answer               | MAIN display            | forward unchanged |
| grounded                     | evidence grounding         | show source trust state | preserve          |
| confidence                   | confidence category        | UI indicator            | preserve          |
| urgency                      | normal/urgent/emergency    | CRITICAL                | preserve          |
| requires_professional_review | safety flag                | warning UI              | preserve          |
| sources                      | citations                  | source cards            | forward           |
| routing_method               | deterministic/llm          | debug only              | logging           |
| graph_path                   | LangGraph execution path   | debug only              | logging/debug     |

---

# 10. DEMO CASES

Give them the exact four core demo cases:

### Case 1 — Clinical

```text
I have fever and headache. What could this mean?
```

Expected:

```text
agent = clinical_agent
```

### Case 2 — Emergency

```text
I am having severe chest pain and difficulty breathing.
```

Expected:

```text
agent = emergency_agent
urgency = emergency
```

### Case 3 — RAG

```text
According to the medical document, what temperature qualifies as fever in the Revised Jones criteria?
```

Expected:

```text
agent = rag_agent
grounded = true
sources != []
```

### Case 4 — Unsupported

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

# 11. INTEGRATION CHECKLIST

Create a practical checklist:

## Vilas

* [ ] AI service URL configured
* [ ] Node → AI request implemented
* [ ] AI response preserved
* [ ] AI errors handled
* [ ] secrets protected
* [ ] health check integrated
* [ ] backend integration tests pass

## Sejal

* [ ] API client connected
* [ ] Clinical response UI
* [ ] Emergency response UI
* [ ] RAG source cards
* [ ] Unsupported state
* [ ] Loading state
* [ ] Error state
* [ ] urgency handling
* [ ] professional-review handling

## Joint

* [ ] Clinical case passes
* [ ] Emergency case passes
* [ ] RAG case passes
* [ ] Unsupported case passes
* [ ] No API contract mismatch
* [ ] Full Flutter → Node → AI → Node → Flutter flow verified

---

# 12. CHANGE CONTROL

Document this rule:

If anyone wants to change:

* request fields
* response fields
* enum values
* agent names
* error schema

they must first notify the other owners and update the API contract documentation.

Never silently create conflicting schemas.

---

# 13. Known Limitations

Include:

* Gemini free-tier quotas may limit live testing
* AI service is an academic prototype
* not a clinical medical device
* local-development setup may differ from deployment
* offline/adaptive features should only be presented as implemented if verified in code

---

# 14. Final Team Goal

The final objective is:

```text
Flutter
   ↓
Node / Express
   ↓
AI Service
   ↓
LangGraph
   ↓
Specialized AI
   ↓
Structured response
   ↓
Node
   ↓
Flutter
```

The team should now focus on **integration and product behavior**, not rebuilding the AI subsystem.

---

# IMPORTANT DOCUMENTATION RULES

1. Inspect the repository before editing.
2. Treat the CURRENT CODE as the source of truth.
3. Do not copy outdated architecture from old markdown files.
4. Do not claim a feature is implemented unless the code confirms it.
5. Clearly mark planned features as planned.
6. Keep README concise enough to be useful.
7. Keep TEAM_HANDOFF practical and developer-oriented.
8. Do not duplicate the full API contract document. Link/reference it instead.
9. Cross-reference:

   * `docs/API_CONTRACTS.md` or the actual existing API contract filename
   * `docs/architecture.md` if it exists
   * `docs/decisions.md` if it exists
10. Inspect the actual filenames and use the correct paths.
11. Do not create duplicate documentation files with slightly different names.
12. If `docs/TEAM_HANDOFF.md` already exists, update it instead of creating another handoff document.
13. Preserve useful existing documentation where it remains accurate.
14. Remove or rewrite stale claims such as:

* custom orchestrator instead of LangGraph
* `general` intent instead of `unsupported`
* old Gemini model names
* old API schemas
* hypothetical project structures

15. Do not claim tests passed unless you actually ran them.

---

# FINAL OUTPUT

After editing, report:

1. README updated
2. TEAM_HANDOFF.md created/updated
3. stale information removed
4. current architecture reflected
5. current API reflected
6. Sejal responsibilities
7. Vilas responsibilities
8. actual validation/test results
9. any remaining blocker

Do not modify application behavior as part of this task.

</USER_REQUEST>
<ADDITIONAL_METADATA>
The current local time is: 2026-08-27T00:05:27+05:30.

The user's current state is as follows:
Active Document: c:\Users\shubh\Downloads\gramhealth-ai\docs\AI_API_CONTRACT.md (LANGUAGE_MARKDOWN)
Cursor is on line: 1
Other open documents:
- c:\Users\shubh\Downloads\gramhealth-ai\ai-service\find_chunk.py (LANGUAGE_PYTHON)
- c:\Users\shubh\Downloads\gramhealth-ai\ai-service\rag\retrieval\vector_store.py (LANGUAGE_PYTHON)
- c:\Users\shubh\Downloads\gramhealth-ai\ai-service\rag\models\schemas.py (LANGUAGE_PYTHON)
- c:\Users\shubh\Downloads\gramhealth-ai\ai-service\requirements.txt (LANGUAGE_UNSPECIFIED)
- c:\Users\shubh\Downloads\gramhealth-ai\README.md (LANGUAGE_MARKDOWN)
</ADDITIONAL_METADATA>
import os
import logging
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from .routes import router as rag_router, sync_router
from .agent_routes import router as agent_router
from .patient_routes import router as patient_router
from rag.config.settings import is_gemini_configured

logger = logging.getLogger(__name__)

app = FastAPI(
    title="GramHealth AI Orchestrator",
    description="Medical Retrieval-Augmented Generation and Agent Orchestrator",
    version="1.1.0"
)

# Enable CORS (allow all origins for flexibility with server-to-server and web clients)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception Handlers to avoid leaking Python stack traces
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"error": True, "message": "Invalid query", "code": "VALIDATION_ERROR"},
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    error_msg = str(exc)
    logger.error(f"Global exception: {error_msg}", exc_info=True)
    
    if "RESOURCE_EXHAUSTED" in error_msg or "429" in error_msg or "quota" in error_msg.lower():
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"error": True, "message": "AI service temporarily unavailable", "code": "MODEL_UNAVAILABLE"},
        )
        
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"error": True, "message": "An internal error occurred.", "code": "AI_SERVICE_ERROR"},
    )

app.include_router(rag_router)
app.include_router(sync_router)
app.include_router(agent_router)
app.include_router(patient_router)

@app.get("/health")
async def health_check():
    """Basic process health check. Does NOT require Gemini generation to report healthy."""
    return {
        "status": "healthy",
        "service": "gramhealth-ai",
        "gemini_configured": is_gemini_configured()
    }

@app.get("/ready")
async def readiness_check():
    """Readiness probe that confirms configuration status without exposing secrets."""
    return {
        "ready": True,
        "service": "gramhealth-ai",
        "gemini_configured": is_gemini_configured()
    }

if __name__ == "__main__":
    import uvicorn
    # Render provides $PORT; defaults to 8001 for local development
    port = int(os.environ.get("PORT", 8001))
    uvicorn.run("api.main:app", host="0.0.0.0", port=port, reload=False)

# touch to reload 1790174109625

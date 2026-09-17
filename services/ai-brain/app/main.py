"""
🟣 NIMMY AI Brain — FastAPI Application
========================================
Core cognitive backend service for Nimmy.
Orchestrates LLM calls, semantic memory retrieval, task parsing, and summarization.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import settings
from .routers import chat, memory, summarize, tasks

app = FastAPI(
    title="Nimmy AI Brain",
    description="Cognitive AI/ML backend service for Nimmy multi-platform assistant",
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware for Web and Mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Subsystem Routers
app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat & Cognition"])
app.include_router(memory.router, prefix="/api/v1/memory", tags=["Semantic Memory"])
app.include_router(summarize.router, prefix="/api/v1/summarize", tags=["Summarization"])
app.include_router(tasks.router, prefix="/api/v1/tasks", tags=["Task Intelligence"])


@app.get("/")
async def root():
    return {
        "service": settings.SERVICE_NAME,
        "status": "online",
        "version": settings.VERSION,
        "model": settings.GEMINI_MODEL,
        "endpoints": [
            "/api/v1/chat",
            "/api/v1/memory",
            "/api/v1/summarize",
            "/api/v1/tasks/parse",
        ],
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": settings.SERVICE_NAME,
        "version": settings.VERSION,
    }


@app.get("/telemetry")
async def telemetry():
    from .services.memory_vault import memory_vault
    return {
        "service": settings.SERVICE_NAME,
        "memory_nodes_count": len(memory_vault.list_all()),
        "gemini_api_configured": bool(settings.GEMINI_API_KEY),
        "model_in_use": settings.GEMINI_MODEL,
        "status": "operational",
    }

"""
🟣 NIMMY AI Brain — FastAPI Application
========================================
Main entry point for Nimmy's AI/ML backend service.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Nimmy AI Brain",
    description="AI/ML backend for Nimmy — your intelligent assistant",
    version="0.1.0",
)

# CORS for web & mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"service": "nimmy-ai-brain", "status": "online", "version": "0.1.0"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


# Routers will be added in Phase 2:
# from .routers import chat, transcribe, summarize, memory, recommend
# app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])
# app.include_router(transcribe.router, prefix="/api/v1/transcribe", tags=["Transcribe"])
# app.include_router(summarize.router, prefix="/api/v1/summarize", tags=["Summarize"])
# app.include_router(memory.router, prefix="/api/v1/memory", tags=["Memory"])
# app.include_router(recommend.router, prefix="/api/v1/recommend", tags=["Recommend"])

"""
🟣 NIMMY AI Brain — Chat Router
=================================
"""

from fastapi import APIRouter, HTTPException
from ..schemas import ChatRequest, ChatResponse
from ..services.llm_engine import llm_engine

router = APIRouter()


@router.post("", response_model=ChatResponse)
async def handle_chat(request: ChatRequest) -> ChatResponse:
    """
    Primary chat and multimodal conversation endpoint.
    Orchestrates prompt understanding, tool dispatch, and conversational response.
    """
    if not request.messages:
        raise HTTPException(status_code=400, detail="Messages list cannot be empty")

    session_id = request.session_id or "default"
    response = await llm_engine.generate_response(
        messages=request.messages,
        session_id=session_id,
        context=request.context,
    )
    return response

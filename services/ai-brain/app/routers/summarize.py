"""
🟣 NIMMY AI Brain — Summarize Router
======================================
"""

import re
from fastapi import APIRouter, HTTPException
from ..schemas import SummarizeRequest, SummarizeResponse

router = APIRouter()


@router.post("", response_model=SummarizeResponse)
async def summarize_text(request: SummarizeRequest) -> SummarizeResponse:
    """
    Summarizes audio transcripts, meeting notes, or long conversations into key action points.
    """
    text = request.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    words = text.split()
    sentences = re.split(r"[.!?]+", text)
    sentences = [s.strip() for s in sentences if len(s.strip()) > 5]

    # Heuristic extraction of top key points
    key_points = []
    for s in sentences:
        if any(w in s.lower() for w in ["task", "must", "need", "should", "schedule", "priority", "important"]):
            key_points.append(s)
        if len(key_points) >= 4:
            break

    if not key_points:
        key_points = sentences[:3] if sentences else [text[:100]]

    summary = (
        f"Summary ({len(words)} words analyzed): "
        + " ".join(key_points[:2])
    )

    return SummarizeResponse(
        summary=summary,
        key_points=key_points,
        word_count=len(words),
    )

"""
🟣 NIMMY AI Brain — Intelligence & Learning Router
===================================================
Endpoints for feedback, corrections, timeline synthesis,
candidate preference promotion, and recording extraction.
"""

from typing import List, Dict, Any
from fastapi import APIRouter, HTTPException
from ..schemas import (
    FeedbackSubmission,
    CorrectionTurnRequest,
    CorrectionRecord,
    TimelineQueryRequest,
    WhatHappenedResponse,
    RecordingExtractRequest,
    RecordingExtractResponse,
)
from ..services.intelligence.correction_engine import correction_engine
from ..services.intelligence.what_happened_engine import what_happened_engine
from ..services.intelligence.recording_processor import recording_processor
from ..services.intelligence.knowledge_router import knowledge_router

router = APIRouter(prefix="/api/v1/intelligence", tags=["Intelligence & Learning"])


@router.post("/feedback")
async def submit_feedback(feedback: FeedbackSubmission) -> Dict[str, Any]:
    """
    Log user thumbs-up / thumbs-down and error classification ("Nimmy Galat Hai").
    """
    # If a negative correction was suggested, route it to the correction engine
    if not feedback.is_positive and feedback.suggested_correction:
        correction_engine.process_correction(
            original_data=feedback.feedback_text or "Previous output",
            corrected_data=feedback.suggested_correction,
            context=feedback.error_category,
        )

    return {
        "status": "recorded",
        "is_positive": feedback.is_positive,
        "error_category": feedback.error_category,
        "message": "Feedback integrated into Nimmy's learning store.",
    }


@router.post("/correct")
async def submit_correction(req: CorrectionTurnRequest) -> Dict[str, Any]:
    """
    Direct user correction ("Nahi, maine 9 PM bola tha").
    Executes non-defensive acknowledgement and registers correction pattern.
    """
    result = correction_engine.process_correction(
        original_data=req.original_data,
        corrected_data=req.corrected_data,
        context=req.context,
    )
    return result


@router.get("/corrections/patterns", response_model=List[CorrectionRecord])
async def get_learned_patterns():
    """
    List recurring correction patterns that are candidate preferences awaiting confirmation.
    """
    return correction_engine.get_candidate_preferences()


@router.post("/corrections/confirm/{record_id}", response_model=CorrectionRecord)
async def confirm_preference_rule(record_id: str):
    """
    User confirms a candidate preference pattern into a permanent default rule.
    """
    record = correction_engine.confirm_candidate_preference(record_id)
    if not record:
        raise HTTPException(status_code=404, detail="Correction pattern not found")
    return record


@router.post("/what-happened", response_model=WhatHappenedResponse)
async def get_what_happened(req: TimelineQueryRequest):
    """
    'Nimmy, kal kya hua?' — Synthesizes timeline across tasks, calendar, notes, memories, and audit events.
    """
    return what_happened_engine.synthesize_timeline(
        target_date=req.target_date or "today"
    )


@router.post("/recording/extract-candidates", response_model=RecordingExtractResponse)
async def extract_recording_candidates(req: RecordingExtractRequest):
    """
    Extracts decisions, facts, tasks, and ideas from transcripts.
    CRITICAL: Does NOT save to permanent memory without explicit confirmation.
    """
    return recording_processor.extract_candidates(req.transcript)


@router.post("/route")
async def route_query(query: str):
    """
    Inspect how Knowledge Router partitions a query (Personal vs External vs Conceptual).
    """
    return knowledge_router.route_query(query)

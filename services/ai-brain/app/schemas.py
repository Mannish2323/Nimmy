"""
🟣 NIMMY AI Brain — Data Models & Schemas
==========================================
Includes typed memory categories, provenance, confidence tiers,
feedback/correction tracking, timeline events, and recording extraction.
"""

from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field
from datetime import datetime


class ToolCall(BaseModel):
    name: str
    arguments: Dict[str, Any]


class ChatMessage(BaseModel):
    role: str = Field(..., description="'user', 'assistant', 'system', or 'tool'")
    content: str
    timestamp: Optional[str] = None


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    session_id: Optional[str] = "default-session"
    user_id: Optional[str] = "user-default"
    stream: bool = False
    context: Optional[Dict[str, Any]] = None


class ChatResponse(BaseModel):
    reply: str
    role: str = "assistant"
    intent: str = "general_conversation"
    tool_calls: List[ToolCall] = []
    session_id: str
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat())


# -------------------------------------------------------------
# 🧠 MEMORY & PROVENANCE SCHEMAS
# -------------------------------------------------------------

class MemoryCategory(str, Enum):
    PROFILE = "profile"
    PREFERENCE = "preference"
    GOAL = "goal"
    PROJECT = "project"
    KNOWLEDGE = "knowledge"
    EVENT = "event"
    IDEA = "idea"
    CORRECTION = "correction"


class ConfidenceTier(str, Enum):
    VERY_HIGH = "very_high"  # 1.00 Explicit user command
    HIGH = "high"            # 0.95 User confirmed candidate
    MEDIUM = "medium"        # 0.80 Repeated consistent pattern
    IMPORTED = "imported"    # 0.75 Synced integration/calendar
    INFERENCE = "inference"  # 0.30 AI deduction (NEVER a fact)
    UNVERIFIED = "unverified"# 0.10 Speculative assumption


class ProvenanceSource(str, Enum):
    USER_EXPLICIT = "user_explicit"
    USER_CONFIRMED = "user_confirmed"
    USER_CORRECTION = "user_correction"
    USER_NOTE = "user_note"
    USER_RECORDING = "user_recording"
    CALENDAR = "calendar"
    TASK_DATABASE = "task_database"
    CONNECTED_SERVICE = "connected_service"
    EXTERNAL_KNOWLEDGE = "external_knowledge"


class MemoryStatus(str, Enum):
    ACTIVE = "active"
    SUPERSEDED = "superseded"
    CONTRADICTED = "contradicted"
    ARCHIVED = "archived"


class MemoryItem(BaseModel):
    id: str
    category: MemoryCategory = MemoryCategory.PREFERENCE
    content: str
    previous_value: Optional[str] = None
    confidence: float = 0.95
    confidence_tier: ConfidenceTier = ConfidenceTier.HIGH
    source_type: ProvenanceSource = ProvenanceSource.USER_EXPLICIT
    source_name: Optional[str] = None
    source_url: Optional[str] = None
    user_confirmed: bool = True
    status: MemoryStatus = MemoryStatus.ACTIVE
    tags: List[str] = []
    version_history: List[Dict[str, Any]] = []
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: Optional[str] = None


class MemoryCreate(BaseModel):
    category: MemoryCategory = MemoryCategory.PREFERENCE
    content: str
    source_type: ProvenanceSource = ProvenanceSource.USER_EXPLICIT
    source_name: Optional[str] = None
    source_url: Optional[str] = None
    confidence: Optional[float] = None  # Auto-calculated by confidence engine if None
    user_confirmed: bool = True
    tags: List[str] = []


class MemorySearchQuery(BaseModel):
    query: str
    limit: int = 5
    category: Optional[MemoryCategory] = None


# -------------------------------------------------------------
# 🚨 CORRECTION & FEEDBACK SCHEMAS ("NIMMY GALAT HAI")
# -------------------------------------------------------------

class FeedbackSubmission(BaseModel):
    session_id: str
    message_id: Optional[str] = None
    is_positive: bool
    error_category: Optional[str] = Field(
        None,
        description="'wrong_information', 'wrong_action', 'wrong_interpretation', 'wrong_memory', 'other'"
    )
    feedback_text: Optional[str] = None
    suggested_correction: Optional[str] = None


class CorrectionTurnRequest(BaseModel):
    original_data: str
    corrected_data: str
    context: Optional[str] = None
    session_id: Optional[str] = "default-session"


class CorrectionRecord(BaseModel):
    id: str
    original_data: str
    corrected_data: str
    context_entity: Optional[str] = None
    repetition_count: int = 1
    is_candidate_preference: bool = False
    user_confirmed_rule: bool = False
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: Optional[str] = None


# -------------------------------------------------------------
# 📅 "WHAT HAPPENED?" TIMELINE SCHEMAS
# -------------------------------------------------------------

class TimelineQueryRequest(BaseModel):
    target_date: Optional[str] = "today"  # 'today', 'yesterday', or 'YYYY-MM-DD'
    user_id: Optional[str] = "user-default"


class TimelineEvent(BaseModel):
    time: str
    source: str  # 'task', 'calendar', 'note', 'memory', 'recording', 'audit'
    title: str
    detail: Optional[str] = None
    status: Optional[str] = "completed"


class WhatHappenedResponse(BaseModel):
    date: str
    summary: str
    events: List[TimelineEvent]
    total_events: int


# -------------------------------------------------------------
# 🎙️ RECORDING TO MEMORY PIPELINE SCHEMAS
# -------------------------------------------------------------

class RecordingExtractRequest(BaseModel):
    transcript: str
    session_id: Optional[str] = None


class ExtractedCandidate(BaseModel):
    category: str  # 'fact', 'decision', 'task', 'date', 'idea'
    content: str
    confidence: float
    suggested_action: str
    requires_user_confirmation: bool = True


class RecordingExtractResponse(BaseModel):
    summary: str
    candidates: List[ExtractedCandidate]
    processed_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())


# -------------------------------------------------------------
# 📝 SUMMARIZE & TASK PARSE SCHEMAS
# -------------------------------------------------------------

class SummarizeRequest(BaseModel):
    text: str
    max_length: int = 250
    style: str = "bullet_points"


class SummarizeResponse(BaseModel):
    summary: str
    key_points: List[str]
    word_count: int
    processed_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())


class TaskParseRequest(BaseModel):
    text: str


class TaskParseResponse(BaseModel):
    title: str
    priority: str = "medium"
    due_date: Optional[str] = None
    estimated_minutes: Optional[int] = 30
    tags: List[str] = []
    suggested_action: str

"""
🟣 NIMMY AI Brain — Data Models & Schemas
==========================================
"""

from typing import List, Optional, Dict, Any
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


class MemoryItem(BaseModel):
    id: str
    category: str
    content: str
    confidence: float = 0.95
    tags: List[str] = []
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())


class MemoryCreate(BaseModel):
    category: str = "General"
    content: str
    confidence: float = 0.95
    tags: List[str] = []


class MemorySearchQuery(BaseModel):
    query: str
    limit: int = 5
    category: Optional[str] = None


class SummarizeRequest(BaseModel):
    text: str
    max_length: int = 250
    style: str = "bullet_points"  # 'bullet_points', 'executive', 'concise'


class SummarizeResponse(BaseModel):
    summary: str
    key_points: List[str]
    word_count: int
    processed_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())


class TaskParseRequest(BaseModel):
    text: str


class TaskParseResponse(BaseModel):
    title: str
    priority: str = "medium"  # urgent, high, medium, low
    due_date: Optional[str] = None
    estimated_minutes: Optional[int] = 30
    tags: List[str] = []
    suggested_action: str

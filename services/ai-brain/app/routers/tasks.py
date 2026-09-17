"""
🟣 NIMMY AI Brain — Tasks Parser Router
========================================
"""

import re
from fastapi import APIRouter, HTTPException
from ..schemas import TaskParseRequest, TaskParseResponse

router = APIRouter()


@router.post("/parse", response_model=TaskParseResponse)
async def parse_task_intent(request: TaskParseRequest) -> TaskParseResponse:
    """
    Parses unstructured text or voice command into a structured priority task.
    """
    text = request.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    lower = text.lower()

    # Priority heuristic
    priority = "medium"
    if any(k in lower for k in ["urgent", "asap", "critical", "immediately", "blocker"]):
        priority = "urgent"
    elif any(k in lower for k in ["high", "important", "crucial"]):
        priority = "high"
    elif any(k in lower for k in ["low", "whenever", "someday", "minor"]):
        priority = "low"

    # Clean title
    title = re.sub(
        r"^(please\s+)?(create\s+a?\s*task|add\s+a?\s*task|remind\s+me\s+to|todo)\s*:?\s*",
        "",
        text,
        flags=re.IGNORECASE,
    ).strip()
    if not title:
        title = text

    # Due date heuristic
    due_date = "Tomorrow"
    if "today" in lower:
        due_date = "Today, 5:00 PM"
    elif "next week" in lower:
        due_date = "Next Monday"
    elif "friday" in lower:
        due_date = "This Friday"

    # Tag extraction
    tags = []
    if any(k in lower for k in ["code", "rust", "go", "python", "flutter", "bug"]):
        tags.append("engineering")
    if any(k in lower for k in ["design", "ui", "ux", "css", "color"]):
        tags.append("design")
    if any(k in lower for k in ["meeting", "call", "sync"]):
        tags.append("meeting")

    return TaskParseResponse(
        title=title,
        priority=priority,
        due_date=due_date,
        estimated_minutes=30 if priority == "medium" else 60,
        tags=tags,
        suggested_action=f"Create {priority.upper()} task in active project queue",
    )

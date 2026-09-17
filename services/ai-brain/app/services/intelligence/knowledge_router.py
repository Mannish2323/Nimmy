"""
🟣 NIMMY Intelligence Layer — Knowledge Source Router
======================================================
Partitions queries into appropriate data sources:
Personal -> Memory/Database; Current/Live -> Verified External APIs; Conceptual -> Foundation AI.
"""

from enum import Enum
from typing import Dict, Any


class KnowledgeSourceType(str, Enum):
    PERSONAL = "personal"                # User memory, tasks, calendar, notes
    CURRENT_EXTERNAL = "current_external"# Real-time weather, stock, external facts
    CONCEPTUAL_AI = "conceptual_ai"      # General science, programming, language explanations


class KnowledgeRouter:
    PERSONAL_KEYWORDS = [
        "my", "mera", "meri", "task", "reminder", "schedule", "meeting",
        "calendar", "note", "remember", "project", "nimmy", "kal kya hua",
        "what did i do", "preference", "email", "todo", "profile"
    ]

    CURRENT_EXTERNAL_KEYWORDS = [
        "weather", "temperature", "aaj ka mausam", "news", "stock", "price",
        "score", "who is the current ceo", "latest", "today in", "currency"
    ]

    @classmethod
    def route_query(cls, query: str) -> Dict[str, Any]:
        q_lower = query.lower()

        # 1. Personal data check (highest privacy, routed internally)
        if any(k in q_lower for k in cls.PERSONAL_KEYWORDS):
            return {
                "route": KnowledgeSourceType.PERSONAL,
                "target": "memory_vault_and_database",
                "requires_external_search": False,
                "provenance_needed": "user_data",
                "rationale": "Query refers to user's personal context, tasks, or memory.",
            }

        # 2. Current external data check (needs live web / API fetch)
        if any(k in q_lower for k in cls.CURRENT_EXTERNAL_KEYWORDS):
            return {
                "route": KnowledgeSourceType.CURRENT_EXTERNAL,
                "target": "trusted_external_api",
                "requires_external_search": True,
                "provenance_needed": "source_url_and_timestamp",
                "rationale": "Query requires verified real-time or external world information.",
            }

        # 3. Default to conceptual foundation model reasoning
        return {
            "route": KnowledgeSourceType.CONCEPTUAL_AI,
            "target": "foundation_ai_knowledge",
            "requires_external_search": False,
            "provenance_needed": "ai_general_knowledge",
            "rationale": "General knowledge or conceptual query.",
        }


knowledge_router = KnowledgeRouter()

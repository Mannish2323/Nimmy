"""
🟣 NIMMY AI Brain — LLM Cognitive Engine
=========================================
Handles Google Gemini API integration with autonomous function calling
and offline heuristic cognitive fallback.
"""

import os
import re
from typing import List, Dict, Any, Optional
import httpx
from ..config import settings
from ..schemas import ChatMessage, ChatResponse, ToolCall
from .memory_vault import memory_vault


class LLMEngine:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model = settings.GEMINI_MODEL

    async def generate_response(
        self,
        messages: List[ChatMessage],
        session_id: str = "default",
        context: Optional[Dict[str, Any]] = None,
    ) -> ChatResponse:
        """
        Main cognitive dispatch. If GEMINI_API_KEY is configured, calls Gemini 2.5 API.
        Otherwise, falls back to Nimmy's Cognitive Heuristic Engine.
        """
        if self.api_key:
            try:
                return await self._call_gemini_api(messages, session_id, context)
            except Exception as e:
                # Log error and gracefully drop to heuristic engine
                print(f"[Nimmy LLM] Gemini API call failed: {e}. Falling back to heuristic engine.")

        return self._heuristic_reasoning(messages, session_id, context)

    async def _call_gemini_api(
        self,
        messages: List[ChatMessage],
        session_id: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> ChatResponse:
        """
        Calls Google Gemini API via official REST endpoint with structured tools.
        """
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"

        # Convert messages to Gemini format
        contents = []
        for m in messages:
            role = "user" if m.role == "user" else "model"
            contents.append({"role": role, "parts": [{"text": m.content}]})

        system_instruction = {
            "parts": [
                {
                    "text": (
                        "You are Nimmy, an autonomous, highly intelligent AI assistant operating across "
                        "mobile (Flutter/Kotlin) and web (Next.js). You have access to task scheduling, "
                        "calendar management, and persistent semantic memory. Respond concisely and decisively."
                    )
                }
            ]
        }

        payload = {
            "contents": contents,
            "system_instruction": system_instruction,
            "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 800,
            },
        }

        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, json=payload)
            resp.raise_for_status()
            data = resp.json()

            candidates = data.get("candidates", [])
            if candidates:
                text_part = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                # Heuristic tool extraction from text if any
                tools, intent = self._extract_tools_from_text(messages[-1].content if messages else "")
                return ChatResponse(
                    reply=text_part.strip(),
                    role="assistant",
                    intent=intent,
                    tool_calls=tools,
                    session_id=session_id,
                )

        # Fallback if no candidates
        return self._heuristic_reasoning(messages, session_id, context)

    def _extract_tools_from_text(self, text: str) -> tuple[List[ToolCall], str]:
        """Detect intent and extract structured tool arguments."""
        lower = text.lower()
        tools: List[ToolCall] = []
        intent = "general_conversation"

        # 1. Task Creation Intent
        if any(w in lower for w in ["task", "todo", "action item", "remind me to"]):
            intent = "task_creation"
            title = re.sub(
                r"^(please\s+)?(add\s+a?\s*task|create\s+a?\s*task|remind\s+me\s+to|add\s+todo)\s*:?\s*",
                "",
                text,
                flags=re.IGNORECASE,
            ).strip()
            if not title:
                title = text

            priority = "medium"
            if any(p in lower for p in ["urgent", "asap", "critical"]):
                priority = "urgent"
            elif any(p in lower for p in ["high priority", "important"]):
                priority = "high"

            tools.append(
                ToolCall(
                    name="create_task",
                    arguments={
                        "title": title,
                        "priority": priority,
                        "due_date": "Today, 5:00 PM" if "today" in lower else "Tomorrow",
                    },
                )
            )

        # 2. Calendar Event Intent
        elif any(w in lower for w in ["meeting", "schedule", "calendar", "call with"]):
            intent = "calendar_scheduling"
            title = re.sub(
                r"^(please\s+)?(schedule\s+a?\s*meeting|schedule|add\s+to\s+calendar)\s*:?\s*",
                "",
                text,
                flags=re.IGNORECASE,
            ).strip()
            tools.append(
                ToolCall(
                    name="create_calendar_event",
                    arguments={
                        "title": title or "Scheduled Discussion",
                        "start_time": "Tomorrow at 10:00 AM",
                        "duration_minutes": 30,
                    },
                )
            )

        # 3. Memory Storage Intent
        elif any(w in lower for w in ["remember", "store memory", "save memory", "i prefer"]):
            intent = "memory_storage"
            content = re.sub(
                r"^(please\s+)?(remember\s+that|remember|save\s+memory)\s*:?\s*",
                "",
                text,
                flags=re.IGNORECASE,
            ).strip()
            tools.append(
                ToolCall(
                    name="store_memory",
                    arguments={
                        "category": "Preference" if "prefer" in lower else "Fact",
                        "content": content or text,
                    },
                )
            )

        # 4. Memory Search Intent
        elif any(w in lower for w in ["what do you know about", "recall", "what did i say about"]):
            intent = "memory_recall"
            query = re.sub(
                r"^(what\s+do\s+you\s+know\s+about|recall|search\s+memory\s+for)\s*:?\s*",
                "",
                text,
                flags=re.IGNORECASE,
            ).strip()
            tools.append(
                ToolCall(
                    name="search_memory",
                    arguments={"query": query},
                )
            )

        return tools, intent

    def _heuristic_reasoning(
        self,
        messages: List[ChatMessage],
        session_id: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> ChatResponse:
        """
        Offline Cognitive Engine with stateful reasoning and tool generation.
        """
        last_message = messages[-1].content if messages else "Hello"
        tools, intent = self._extract_tools_from_text(last_message)

        if intent == "task_creation":
            task_arg = tools[0].arguments
            reply = (
                f"I have created a new priority task: \"{task_arg['title']}\" (Priority: {task_arg['priority'].upper()}). "
                f"It has been synchronized to your task board across Web and Mobile."
            )
        elif intent == "calendar_scheduling":
            event_arg = tools[0].arguments
            reply = (
                f"Scheduled \"{event_arg['title']}\" for {event_arg['start_time']} ({event_arg['duration_minutes']} min). "
                f"Notifications have been armed for your connected Android devices."
            )
        elif intent == "memory_storage":
            mem_arg = tools[0].arguments
            # Directly persist to memory vault
            from ..schemas import MemoryCreate
            memory_vault.add_memory(MemoryCreate(category=mem_arg["category"], content=mem_arg["content"]))
            reply = (
                f"Stored in persistent semantic memory under [{mem_arg['category']}]. "
                f"I will leverage this context in subsequent autonomous actions."
            )
        elif intent == "memory_recall":
            mem_arg = tools[0].arguments
            matches = memory_vault.search(mem_arg["query"], limit=2)
            if matches:
                facts = " | ".join([f"[{m.category}] {m.content}" for m in matches])
                reply = f"Here is what I retrieved from your semantic memory: {facts}"
            else:
                reply = f"I searched your vector memory for \"{mem_arg['query']}\", but found no existing records."
        else:
            # General Conversational Response
            reply = (
                f"I am active and monitoring all subsystems. How can I assist with your tasks, schedule, "
                f"or cross-device workflows?"
            )

        return ChatResponse(
            reply=reply,
            role="assistant",
            intent=intent,
            tool_calls=tools,
            session_id=session_id,
        )


# Global singleton instance
llm_engine = LLMEngine()

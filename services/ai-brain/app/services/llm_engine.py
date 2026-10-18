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
        Main cognitive dispatch. If GEMINI_API_KEY is configured, calls Gemini API.
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
                        "You are Nimmy, an autonomous, highly intelligent voice-first personal AI OS. "
                        "All state-changing actions and database writes must pass through controlled typed "
                        "tools (create_reminder, save_memory, search_memory). Never claim an action has been "
                        "executed until confirmed and validated by the application ToolRegistry. "
                        "Respond concisely and decisively."
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

        # 1. Reminder Creation Intent (MVP Tool: create_reminder)
        if any(w in lower for w in ["remind me to", "set a reminder", "create reminder"]):
            intent = "reminder_creation"
            title = re.sub(
                r"^(please\s+)?(remind\s+me\s+to|set\s+a\s+reminder\s+to|create\s+reminder\s+for)\s*:?\s*",
                "",
                text,
                flags=re.IGNORECASE,
            ).strip()
            tools.append(
                ToolCall(
                    name="create_reminder",
                    arguments={
                        "title": title or text,
                        "requires_confirmation": True,
                    },
                )
            )

        # 2. Task Creation Intent (Phase 3 - controlled deferred)
        elif any(w in lower for w in ["task", "todo", "action item"]):
            intent = "task_creation"
            # Task creation is intentionally deferred until Phase 3 typed executor

        # 3. Calendar Event Intent (Phase 4 - controlled deferred)
        elif any(w in lower for w in ["meeting", "schedule", "calendar", "call with"]):
            intent = "calendar_scheduling"
            # Calendar actions deferred until Phase 4 OAuth/provider integration

        # 4. Memory Storage Intent (MVP Tool: save_memory)
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
                    name="save_memory",
                    arguments={
                        "category": "preference" if "prefer" in lower else "other",
                        "importance": "normal",
                        "content": content or text,
                        "requires_confirmation": True,
                    },
                )
            )

        # 5. Memory Search Intent (MVP Tool: search_memory)
        elif any(w in lower for w in ["what do you know about", "recall", "what did i say about", "search memory"]):
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
        Strictly produces ToolProposals; never mutates storage directly.
        """
        last_message = messages[-1].content if messages else "Hello"
        tools, intent = self._extract_tools_from_text(last_message)

        if intent == "reminder_creation":
            reminder_title = tools[0].arguments.get("title", "reminder") if tools else "reminder"
            reply = (
                f"I prepared a reminder proposal for \"{reminder_title}\". "
                "Please confirm to schedule this reminder."
            )
        elif intent == "task_creation":
            reply = (
                "I understood that as a task request, but task creation is scheduled for "
                "Phase 3 and is not yet available. Nothing was changed."
            )
        elif intent == "calendar_scheduling":
            reply = (
                "I understood that as a calendar request, but calendar integration is scheduled "
                "for Phase 4 and is not connected yet. Nothing was changed."
            )
        elif intent == "memory_storage":
            reply = (
                "I prepared a memory proposal. The application will ask for your "
                "confirmation before saving it to your explicit memory."
            )
        elif intent == "memory_recall":
            mem_arg = tools[0].arguments if tools else {}
            query = mem_arg.get("query", "")
            # If the application supplied retrieved memories in context:
            retrieved = context.get("retrieved_memories") if context else None
            if retrieved:
                facts = " | ".join([f"[{m.get('category', 'general')}] {m.get('content', '')}" for m in retrieved])
                reply = f"Here is what I retrieved from your memory: {facts}"
            else:
                reply = (
                    f"I prepared a memory search proposal for \"{query}\". "
                    "The application ToolRegistry will execute the search across your local and cloud records."
                )
        else:
            # General Conversational Response
            reply = (
                "I am active and monitoring all subsystems. How can I assist with your reminders, "
                "memory, or cross-device workflows?"
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

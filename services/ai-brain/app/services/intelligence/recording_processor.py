"""
🟣 NIMMY Intelligence Layer — Recording to Memory Pipeline
===========================================================
Extracts structured candidates (facts, decisions, tasks, dates, ideas) from audio transcripts.
CRITICAL RULE: Candidate memories NEVER become permanent without explicit user confirmation.
"""

import re
from typing import List
from ...schemas import ExtractedCandidate, RecordingExtractResponse


class RecordingProcessor:
    @classmethod
    def extract_candidates(cls, transcript: str) -> RecordingExtractResponse:
        candidates: List[ExtractedCandidate] = []
        lines = transcript.split(".")

        for line in lines:
            line_str = line.strip()
            if not line_str or len(line_str) < 6:
                continue

            lower = line_str.lower()

            # 1. Decision extraction
            if any(k in lower for k in ["decided", "approve", "agreed", "finalized", "faisla"]):
                candidates.append(
                    ExtractedCandidate(
                        category="decision",
                        content=line_str,
                        confidence=0.88,
                        suggested_action="Save decision to Knowledge Memory",
                        requires_user_confirmation=True,
                    )
                )

            # 2. Task / Action item extraction
            elif any(k in lower for k in ["need to", "have to", "karna hai", "deadline", "bhejna", "submit", "todo"]):
                candidates.append(
                    ExtractedCandidate(
                        category="task",
                        content=line_str,
                        confidence=0.85,
                        suggested_action="Create task candidate",
                        requires_user_confirmation=True,
                    )
                )

            # 3. Idea extraction
            elif any(k in lower for k in ["idea", "concept", "what if", "maybe we can", "soch"]):
                candidates.append(
                    ExtractedCandidate(
                        category="idea",
                        content=line_str,
                        confidence=0.80,
                        suggested_action="Store in Idea Memory bank",
                        requires_user_confirmation=True,
                    )
                )

            # 4. Factual statement
            elif any(k in lower for k in ["is called", "uses", "we are building", "version"]):
                candidates.append(
                    ExtractedCandidate(
                        category="fact",
                        content=line_str,
                        confidence=0.82,
                        suggested_action="Save to Project/Knowledge Memory",
                        requires_user_confirmation=True,
                    )
                )

        # Default fallback if no specific keywords triggered
        if not candidates and transcript.strip():
            candidates.append(
                ExtractedCandidate(
                    category="summary",
                    content=transcript[:120] + "...",
                    confidence=0.75,
                    suggested_action="Review transcript summary",
                    requires_user_confirmation=True,
                )
            )

        summary = f"Extracted {len(candidates)} actionable candidate(s) from audio recording transcript. None saved to permanent memory pending user approval."

        return RecordingExtractResponse(
            summary=summary,
            candidates=candidates,
        )


recording_processor = RecordingProcessor()

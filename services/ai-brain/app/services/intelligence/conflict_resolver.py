"""
🟣 NIMMY Intelligence Layer — Conflict Resolver
=================================================
Enforces the strict information precedence hierarchy:
Current Explicit Instruction > User Confirmed > Recent User Info > Saved Memory > Connected Data > Inference.
Old memories NEVER blindly override a current explicit instruction.
"""

from typing import Dict, Any, Optional
from ...schemas import MemoryItem, MemoryStatus


class ConflictResolutionResult:
    def __init__(
        self,
        winner_value: str,
        winner_source: str,
        conflict_detected: bool,
        overridden_memory_id: Optional[str] = None,
        rationale: str = "",
    ):
        self.winner_value = winner_value
        self.winner_source = winner_source
        self.conflict_detected = conflict_detected
        self.overridden_memory_id = overridden_memory_id
        self.rationale = rationale

    def to_dict(self) -> Dict[str, Any]:
        return {
            "winner_value": self.winner_value,
            "winner_source": self.winner_source,
            "conflict_detected": self.conflict_detected,
            "overridden_memory_id": self.overridden_memory_id,
            "rationale": self.rationale,
        }


class ConflictResolver:
    # Priority rank (higher number = higher priority)
    PRECEDENCE_RANKS = {
        "current_explicit_instruction": 100,
        "user_confirmed_information": 90,
        "recent_user_information": 80,
        "saved_memory": 70,
        "connected_data": 60,
        "ai_inference": 20,
    }

    @classmethod
    def resolve_instruction_vs_memory(
        cls,
        current_instruction: str,
        candidate_memory: Optional[MemoryItem],
    ) -> ConflictResolutionResult:
        """
        When current user input might contradict a stored memory (e.g. 'preferred reminder 8 AM'
        vs 'remind me at 10 AM today').
        The current instruction ALWAYS takes precedence.
        """
        if not candidate_memory:
            return ConflictResolutionResult(
                winner_value=current_instruction,
                winner_source="current_explicit_instruction",
                conflict_detected=False,
                rationale="No existing memory conflict.",
            )

        # Check for direct conflict indicators
        curr_lower = current_instruction.lower()
        mem_lower = candidate_memory.content.lower()

        # If current instruction contains explicit temporal overrides ('today', 'now', 'this time', 'aaj')
        is_override = any(k in curr_lower for k in ["this time", "today", "aaj", "ab", "now", "instead", "override", "nahi", "no"])

        if is_override or curr_lower != mem_lower:
            return ConflictResolutionResult(
                winner_value=current_instruction,
                winner_source="current_explicit_instruction",
                conflict_detected=True,
                overridden_memory_id=candidate_memory.id,
                rationale=f"Current user instruction overrides saved {candidate_memory.category.value} memory (ID: {candidate_memory.id}).",
            )

        return ConflictResolutionResult(
            winner_value=candidate_memory.content,
            winner_source="saved_memory",
            conflict_detected=False,
            rationale="Current input aligns with stored memory.",
        )

    @classmethod
    def evolve_memory(
        cls,
        old_memory: MemoryItem,
        new_content: str,
        new_source_name: str = "User update",
    ) -> MemoryItem:
        """
        When user permanently updates a preference/fact ('I used to like X, now I prefer Y').
        Mark old memory as superseded and preserve version history.
        """
        version_entry = {
            "value": old_memory.content,
            "superseded_at": old_memory.updated_at or old_memory.created_at,
            "source": old_memory.source_name,
        }

        old_memory.previous_value = old_memory.content
        old_memory.content = new_content
        old_memory.status = MemoryStatus.ACTIVE
        old_memory.version_history.append(version_entry)
        old_memory.source_name = new_source_name
        return old_memory


conflict_resolver = ConflictResolver()

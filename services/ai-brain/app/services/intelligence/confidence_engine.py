"""
🟣 NIMMY Intelligence Layer — Confidence Engine
=================================================
Assigns deterministic confidence scores and tiers based on provenance.
CRITICAL RULE: AI inference is capped at 0.30 and is NEVER stored as fact.
"""

from typing import Tuple
from ...schemas import ProvenanceSource, ConfidenceTier


class ConfidenceEngine:
    TIER_SCORES = {
        ConfidenceTier.VERY_HIGH: 1.00,
        ConfidenceTier.HIGH: 0.95,
        ConfidenceTier.MEDIUM: 0.80,
        ConfidenceTier.IMPORTED: 0.75,
        ConfidenceTier.INFERENCE: 0.30,
        ConfidenceTier.UNVERIFIED: 0.10,
    }

    SOURCE_DEFAULT_TIERS = {
        ProvenanceSource.USER_EXPLICIT: ConfidenceTier.VERY_HIGH,
        ProvenanceSource.USER_CONFIRMED: ConfidenceTier.HIGH,
        ProvenanceSource.USER_CORRECTION: ConfidenceTier.VERY_HIGH,
        ProvenanceSource.USER_NOTE: ConfidenceTier.HIGH,
        ProvenanceSource.USER_RECORDING: ConfidenceTier.MEDIUM,
        ProvenanceSource.CALENDAR: ConfidenceTier.IMPORTED,
        ProvenanceSource.TASK_DATABASE: ConfidenceTier.IMPORTED,
        ProvenanceSource.CONNECTED_SERVICE: ConfidenceTier.IMPORTED,
        ProvenanceSource.EXTERNAL_KNOWLEDGE: ConfidenceTier.MEDIUM,
    }

    @classmethod
    def evaluate(
        cls,
        source: ProvenanceSource,
        is_user_confirmed: bool = False,
        is_ai_inference: bool = False,
        repetition_count: int = 1,
    ) -> Tuple[float, ConfidenceTier]:
        """
        Compute confidence score and tier for a piece of information.
        """
        # Hard constraint: AI inference is capped at 0.30 and cannot be treated as fact
        if is_ai_inference:
            return 0.30, ConfidenceTier.INFERENCE

        if source == ProvenanceSource.USER_EXPLICIT or source == ProvenanceSource.USER_CORRECTION:
            return 1.00, ConfidenceTier.VERY_HIGH

        if is_user_confirmed or source == ProvenanceSource.USER_CONFIRMED:
            return 0.95, ConfidenceTier.HIGH

        if repetition_count >= 3:
            return 0.85, ConfidenceTier.HIGH
        elif repetition_count >= 2:
            return 0.80, ConfidenceTier.MEDIUM

        tier = cls.SOURCE_DEFAULT_TIERS.get(source, ConfidenceTier.UNVERIFIED)
        score = cls.TIER_SCORES.get(tier, 0.50)
        return score, tier

    @classmethod
    def can_store_as_fact(cls, score: float, tier: ConfidenceTier) -> bool:
        """
        AI inference (< 0.50) can NEVER be stored as a standalone fact.
        """
        if tier in (ConfidenceTier.INFERENCE, ConfidenceTier.UNVERIFIED):
            return False
        return score >= 0.70


confidence_engine = ConfidenceEngine()

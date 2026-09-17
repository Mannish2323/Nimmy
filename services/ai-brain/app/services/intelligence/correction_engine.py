"""
🟣 NIMMY Intelligence Layer — Mistake & Correction Engine
==========================================================
Handles user corrections non-defensively ("Nimmy Galat Hai").
Detects conflicts, marks previous interpretation incorrect, records correction patterns,
and elevates recurring patterns to candidate preferences for explicit confirmation.
"""

import re
from typing import Dict, Any, List, Optional
from datetime import datetime
from ...schemas import CorrectionRecord


class CorrectionEngine:
    def __init__(self):
        self._corrections: List[CorrectionRecord] = []

    def process_correction(
        self,
        original_data: str,
        corrected_data: str,
        context: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Record a correction turn non-defensively.
        """
        # Check if this correction pattern was previously registered
        existing = next(
            (c for c in self._corrections if c.original_data.lower() == original_data.lower()),
            None,
        )

        if existing:
            existing.repetition_count += 1
            existing.corrected_data = corrected_data
            existing.updated_at = datetime.utcnow().isoformat()

            # If user corrects the same thing twice or more -> promote to candidate preference
            if existing.repetition_count >= 2:
                existing.is_candidate_preference = True

            record = existing
        else:
            record_id = f"corr-{int(datetime.utcnow().timestamp() * 1000)}"
            record = CorrectionRecord(
                id=record_id,
                original_data=original_data,
                corrected_data=corrected_data,
                context_entity=context,
                repetition_count=1,
                is_candidate_preference=False,
                user_confirmed_rule=False,
                created_at=datetime.utcnow().isoformat(),
            )
            self._corrections.append(record)

        # Generate non-defensive response
        response_text = self._build_humble_acknowledgement(original_data, corrected_data, record.is_candidate_preference)

        return {
            "record": record,
            "response": response_text,
            "pattern_learned": record.is_candidate_preference,
            "repetition_count": record.repetition_count,
        }

    def _build_humble_acknowledgement(
        self, original: str, corrected: str, is_candidate: bool
    ) -> str:
        base = f"Understood. I made an incorrect interpretation. I have updated it from '{original}' to '{corrected}'."
        if is_candidate:
            base += f" You have mentioned this preference {corrected} multiple times. Should I remember this as your permanent default rule?"
        return base

    def get_candidate_preferences(self) -> List[CorrectionRecord]:
        """
        Return all learned correction patterns ready for explicit user confirmation.
        """
        return [c for c in self._corrections if c.is_candidate_preference and not c.user_confirmed_rule]

    def confirm_candidate_preference(self, record_id: str) -> Optional[CorrectionRecord]:
        record = next((c for c in self._corrections if c.id == record_id), None)
        if record:
            record.user_confirmed_rule = True
            record.updated_at = datetime.utcnow().isoformat()
        return record

    def list_corrections(self) -> List[CorrectionRecord]:
        return self._corrections


correction_engine = CorrectionEngine()

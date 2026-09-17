"""
🟣 NIMMY AI Brain — Semantic Memory Vault
==========================================
In-memory semantic vector store supporting the 8 memory categories,
provenance tracking, deterministic confidence tiers, and version history.
"""

import math
import re
from typing import List, Optional
from datetime import datetime
from ..schemas import (
    MemoryItem,
    MemoryCreate,
    MemoryCategory,
    ConfidenceTier,
    ProvenanceSource,
    MemoryStatus,
)
from .intelligence.confidence_engine import confidence_engine
from .intelligence.conflict_resolver import conflict_resolver


class SemanticMemoryVault:
    def __init__(self):
        self._memories: List[MemoryItem] = [
            MemoryItem(
                id="mem-seed-1",
                category=MemoryCategory.PREFERENCE,
                content="User prefers deep cosmic obsidian UI with vibrant purple and cyan accents.",
                confidence=1.00,
                confidence_tier=ConfidenceTier.VERY_HIGH,
                source_type=ProvenanceSource.USER_EXPLICIT,
                source_name="User explicit command",
                user_confirmed=True,
                status=MemoryStatus.ACTIVE,
                tags=["ui", "theme", "preference"],
                created_at=datetime.utcnow().isoformat(),
            ),
            MemoryItem(
                id="mem-seed-2",
                category=MemoryCategory.PROJECT,
                content="Nimmy architecture: Kotlin captures audio; Go Gateway routes WebSockets; Rust handles audio DSP.",
                confidence=0.95,
                confidence_tier=ConfidenceTier.HIGH,
                source_type=ProvenanceSource.USER_CONFIRMED,
                source_name="Architecture specification",
                user_confirmed=True,
                status=MemoryStatus.ACTIVE,
                tags=["architecture", "kotlin", "go", "rust"],
                created_at=datetime.utcnow().isoformat(),
            ),
            MemoryItem(
                id="mem-seed-3",
                category=MemoryCategory.EVENT,
                content="Daily engineering sync scheduled at 10:00 AM. Sprint review on Thursdays.",
                confidence=0.75,
                confidence_tier=ConfidenceTier.IMPORTED,
                source_type=ProvenanceSource.CALENDAR,
                source_name="Connected Google Calendar",
                user_confirmed=True,
                status=MemoryStatus.ACTIVE,
                tags=["calendar", "sync", "routine"],
                created_at=datetime.utcnow().isoformat(),
            ),
        ]

    def _tokenize(self, text: str) -> set[str]:
        words = re.findall(r"\b\w+\b", text.lower())
        stop_words = {"the", "a", "an", "is", "in", "at", "of", "on", "and", "to", "with", "for"}
        return {w for w in words if w not in stop_words and len(w) > 2}

    def _compute_similarity(self, query: str, document: str) -> float:
        query_tokens = self._tokenize(query)
        doc_tokens = self._tokenize(document)
        if not query_tokens or not doc_tokens:
            return 0.0

        intersection = query_tokens.intersection(doc_tokens)
        union = query_tokens.union(doc_tokens)
        jaccard = len(intersection) / len(union)

        # Keyword boost
        keyword_boost = len(intersection) * 0.15
        return min(1.0, jaccard + keyword_boost)

    def add_memory(self, item: MemoryCreate) -> MemoryItem:
        # Calculate confidence via confidence engine if not explicitly given
        if item.confidence is not None:
            score = item.confidence
            tier = ConfidenceTier.HIGH if score >= 0.90 else ConfidenceTier.MEDIUM
        else:
            score, tier = confidence_engine.evaluate(
                source=item.source_type,
                is_user_confirmed=item.user_confirmed,
            )

        # Check for conflicts with existing active memories in this category
        existing_conflict = next(
            (m for m in self._memories if m.status == MemoryStatus.ACTIVE and m.category == item.category),
            None
        )

        new_id = f"mem-{int(datetime.utcnow().timestamp() * 1000)}"

        if existing_conflict:
            # Check if this new memory supersedes the old one
            resolution = conflict_resolver.resolve_instruction_vs_memory(
                current_instruction=item.content,
                candidate_memory=existing_conflict,
            )
            if resolution.conflict_detected:
                # Evolve the existing memory node, archiving old version
                conflict_resolver.evolve_memory(
                    existing_conflict,
                    item.content,
                    new_source_name=item.source_name or "User update",
                )
                existing_conflict.updated_at = datetime.utcnow().isoformat()
                return existing_conflict

        memory = MemoryItem(
            id=new_id,
            category=item.category,
            content=item.content,
            confidence=score,
            confidence_tier=tier,
            source_type=item.source_type,
            source_name=item.source_name or "Direct Input",
            source_url=item.source_url,
            user_confirmed=item.user_confirmed,
            status=MemoryStatus.ACTIVE,
            tags=item.tags,
            created_at=datetime.utcnow().isoformat(),
        )
        self._memories.insert(0, memory)
        return memory

    def search(
        self, query: str, limit: int = 5, category: Optional[MemoryCategory] = None
    ) -> List[MemoryItem]:
        scored = []
        for mem in self._memories:
            if mem.status != MemoryStatus.ACTIVE:
                continue
            if category and mem.category != category:
                continue
            score = self._compute_similarity(query, f"{mem.category.value} {mem.content} {' '.join(mem.tags)}")
            scored.append((score, mem))

        # Sort by similarity score descending
        scored.sort(key=lambda x: x[0], reverse=True)

        # Return matches with positive score or fallback to top active items
        results = [m for s, m in scored if s > 0.05][:limit]
        if not results:
            results = [m for m in self._memories if m.status == MemoryStatus.ACTIVE][:limit]
        return results

    def list_all(self, limit: int = 50, include_superseded: bool = False) -> List[MemoryItem]:
        if include_superseded:
            return self._memories[:limit]
        return [m for m in self._memories if m.status == MemoryStatus.ACTIVE][:limit]

    def delete(self, memory_id: str) -> bool:
        initial_len = len(self._memories)
        self._memories = [m for m in self._memories if m.id != memory_id]
        return len(self._memories) < initial_len


# Global singleton instance
memory_vault = SemanticMemoryVault()

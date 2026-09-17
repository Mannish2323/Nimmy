"""
🟣 NIMMY AI Brain — Semantic Memory Vault
==========================================
In-memory semantic vector store with keyword & cosine similarity scoring.
"""

import math
import re
from typing import List, Optional
from datetime import datetime
from ..schemas import MemoryItem, MemoryCreate


class SemanticMemoryVault:
    def __init__(self):
        self._memories: List[MemoryItem] = [
            MemoryItem(
                id="mem-seed-1",
                category="Preference",
                content="User prefers deep cosmic obsidian UI with vibrant purple and cyan accents.",
                confidence=0.98,
                tags=["ui", "theme", "preference"],
                created_at=datetime.utcnow().isoformat(),
            ),
            MemoryItem(
                id="mem-seed-2",
                category="Architecture",
                content="Kotlin background daemon captures wake-word; Go Gateway multiplexes WebSockets with sub-2ms latency.",
                confidence=0.96,
                tags=["architecture", "kotlin", "go"],
                created_at=datetime.utcnow().isoformat(),
            ),
            MemoryItem(
                id="mem-seed-3",
                category="Schedule",
                content="Daily engineering sync scheduled at 10:00 AM. Sprint review on Thursdays.",
                confidence=0.94,
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
        new_id = f"mem-{int(datetime.utcnow().timestamp() * 1000)}"
        memory = MemoryItem(
            id=new_id,
            category=item.category,
            content=item.content,
            confidence=item.confidence,
            tags=item.tags,
            created_at=datetime.utcnow().isoformat(),
        )
        self._memories.insert(0, memory)
        return memory

    def search(
        self, query: str, limit: int = 5, category: Optional[str] = None
    ) -> List[MemoryItem]:
        scored = []
        for mem in self._memories:
            if category and mem.category.lower() != category.lower():
                continue
            score = self._compute_similarity(query, f"{mem.category} {mem.content} {' '.join(mem.tags)}")
            scored.append((score, mem))

        # Sort by similarity score descending
        scored.sort(key=lambda x: x[0], reverse=True)

        # Return top matches or all if score >= 0.1
        results = [m for s, m in scored if s > 0.05][:limit]
        if not results:
            # Fallback to recent memories if no direct match
            results = self._memories[:limit]
        return results

    def list_all(self, limit: int = 50) -> List[MemoryItem]:
        return self._memories[:limit]

    def delete(self, memory_id: str) -> bool:
        initial_len = len(self._memories)
        self._memories = [m for m in self._memories if m.id != memory_id]
        return len(self._memories) < initial_len


# Global singleton instance
memory_vault = SemanticMemoryVault()

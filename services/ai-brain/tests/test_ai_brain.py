"""
Unit & Integration Tests for Nimmy AI Brain Subsystems
======================================================
Tests:
- FastAPI endpoints (root, health, telemetry)
- Confidence Engine (deterministic confidence & AI inference cap <= 0.30)
- Knowledge Router (personal, live external, conceptual AI routing)
- Conflict Resolver (instruction priority & memory evolution)
- Mistake & Correction Engine (non-defensive correction & candidate promotion)
- What Happened Engine (multi-source timeline assembly)
- Memory Vault (save, retrieve, search)
"""

import unittest
from datetime import datetime
from fastapi.testclient import TestClient

from app.main import app
from app.config import settings
from app.schemas import (
    ProvenanceSource,
    ConfidenceTier,
    MemoryItem,
    MemoryCreate,
    MemoryCategory,
    MemoryStatus,
)
from app.services.intelligence.confidence_engine import confidence_engine
from app.services.intelligence.knowledge_router import (
    knowledge_router,
    KnowledgeSourceType,
)
from app.services.intelligence.conflict_resolver import conflict_resolver
from app.services.intelligence.correction_engine import CorrectionEngine
from app.services.intelligence.what_happened_engine import what_happened_engine
from app.services.memory_vault import SemanticMemoryVault


class TestAIBrainSubsystems(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_root_endpoint(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "online")
        self.assertEqual(data["service"], settings.SERVICE_NAME)

    def test_health_endpoint(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")

    def test_confidence_engine_ai_inference_cap(self):
        score, tier = confidence_engine.evaluate(
            source=ProvenanceSource.EXTERNAL_KNOWLEDGE,
            is_ai_inference=True,
        )
        self.assertLessEqual(score, 0.30)
        self.assertEqual(tier, ConfidenceTier.INFERENCE)
        self.assertFalse(confidence_engine.can_store_as_fact(score, tier))

    def test_confidence_engine_user_explicit(self):
        score, tier = confidence_engine.evaluate(
            source=ProvenanceSource.USER_EXPLICIT,
        )
        self.assertEqual(score, 1.00)
        self.assertEqual(tier, ConfidenceTier.VERY_HIGH)
        self.assertTrue(confidence_engine.can_store_as_fact(score, tier))

    def test_confidence_engine_repetition_boost(self):
        score, tier = confidence_engine.evaluate(
            source=ProvenanceSource.USER_RECORDING,
            repetition_count=3,
        )
        self.assertGreaterEqual(score, 0.85)
        self.assertEqual(tier, ConfidenceTier.HIGH)

    def test_knowledge_router(self):
        # Personal
        res_personal = knowledge_router.route_query("Nimmy, what is my meeting schedule?")
        self.assertEqual(res_personal["route"], KnowledgeSourceType.PERSONAL)
        self.assertFalse(res_personal["requires_external_search"])

        # External Live
        res_external = knowledge_router.route_query("What is the current temperature in Mumbai?")
        self.assertEqual(res_external["route"], KnowledgeSourceType.CURRENT_EXTERNAL)
        self.assertTrue(res_external["requires_external_search"])

        # Conceptual AI
        res_ai = knowledge_router.route_query("Explain quantum computing entanglement simply")
        self.assertEqual(res_ai["route"], KnowledgeSourceType.CONCEPTUAL_AI)
        self.assertFalse(res_ai["requires_external_search"])

    def test_conflict_resolver_instruction_overrides_memory(self):
        old_mem = MemoryItem(
            id="mem-1",
            content="Preferred daily standup at 9:00 AM",
            category=MemoryCategory.PREFERENCE,
            confidence_score=0.9,
            source=ProvenanceSource.USER_EXPLICIT,
            status=MemoryStatus.ACTIVE,
            created_at=datetime.utcnow().isoformat(),
        )

        result = conflict_resolver.resolve_instruction_vs_memory(
            current_instruction="Schedule daily standup today at 11:00 AM instead",
            candidate_memory=old_mem,
        )

        self.assertTrue(result.conflict_detected)
        self.assertEqual(result.winner_source, "current_explicit_instruction")
        self.assertIn("11:00 AM", result.winner_value)

    def test_conflict_resolver_evolve_memory(self):
        old_mem = MemoryItem(
            id="mem-2",
            content="Primary editor is VS Code",
            category=MemoryCategory.PREFERENCE,
            confidence_score=0.95,
            source=ProvenanceSource.USER_CONFIRMED,
            status=MemoryStatus.ACTIVE,
            created_at=datetime.utcnow().isoformat(),
        )

        evolved = conflict_resolver.evolve_memory(
            old_memory=old_mem,
            new_content="Primary editor is Cursor",
            new_source_name="User explicit update",
        )

        self.assertEqual(evolved.content, "Primary editor is Cursor")
        self.assertEqual(evolved.previous_value, "Primary editor is VS Code")
        self.assertEqual(len(evolved.version_history), 1)

    def test_correction_engine_promotion_to_candidate_preference(self):
        engine = CorrectionEngine()

        # First correction
        res1 = engine.process_correction(
            original_data="remind me at 8 PM",
            corrected_data="remind me at 9 PM",
            context="reminder_time",
        )
        self.assertFalse(res1["pattern_learned"])
        self.assertEqual(res1["repetition_count"], 1)

        # Second correction with same original data pattern
        res2 = engine.process_correction(
            original_data="remind me at 8 PM",
            corrected_data="remind me at 9 PM",
            context="reminder_time",
        )
        self.assertTrue(res2["pattern_learned"])
        self.assertEqual(res2["repetition_count"], 2)

        candidates = engine.get_candidate_preferences()
        self.assertEqual(len(candidates), 1)

        # Confirm candidate preference
        confirmed = engine.confirm_candidate_preference(candidates[0].id)
        self.assertIsNotNone(confirmed)
        self.assertTrue(confirmed.user_confirmed_rule)
        self.assertEqual(len(engine.get_candidate_preferences()), 0)

    def test_what_happened_timeline_synthesis(self):
        tasks = [
            {"time": "10:00 AM", "title": "Review PR #42", "priority": "high", "status": "completed"}
        ]
        events = [
            {"time": "02:00 PM", "title": "Client Sync", "detail": "Sprint progress demo"}
        ]

        response = what_happened_engine.synthesize_timeline(
            target_date="today",
            user_tasks=tasks,
            user_events=events,
        )

        self.assertGreaterEqual(response.total_events, 2)
        titles = [e.title for e in response.events]
        self.assertIn("Review PR #42", titles)
        self.assertIn("Client Sync", titles)

    def test_memory_vault_operations(self):
        vault = SemanticMemoryVault()
        item = MemoryCreate(
            category=MemoryCategory.PREFERENCE,
            content="User prefers dark theme with cosmic violet accents",
            confidence=0.95,
            source_type=ProvenanceSource.USER_EXPLICIT,
            source_name="Direct user settings",
            user_confirmed=True,
            tags=["theme", "ui"],
        )
        mem = vault.add_memory(item)

        self.assertIsNotNone(mem.id)
        self.assertEqual(mem.content, item.content)

        # Search
        results = vault.search("cosmic violet")
        self.assertGreaterEqual(len(results), 1)
        self.assertEqual(results[0].id, mem.id)

        # Delete
        deleted = vault.delete(mem.id)
        self.assertTrue(deleted)

    def test_telemetry_endpoint(self):
        response = self.client.get("/telemetry")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "operational")
        self.assertIn("memory_nodes_count", data)

    def test_intelligence_endpoints(self):
        # Route query endpoint
        res_route = self.client.post("/api/v1/intelligence/route?query=What+is+my+schedule")
        self.assertEqual(res_route.status_code, 200)
        self.assertEqual(res_route.json()["route"], "personal")

        # Feedback endpoint
        res_feedback = self.client.post("/api/v1/intelligence/feedback", json={
            "session_id": "test-session-123",
            "is_positive": True,
            "feedback_text": "Accurate response",
        })
        self.assertEqual(res_feedback.status_code, 200)
        self.assertEqual(res_feedback.json()["status"], "recorded")

        # What happened endpoint
        res_what = self.client.post("/api/v1/intelligence/what-happened", json={
            "target_date": "today",
        })
        self.assertEqual(res_what.status_code, 200)
        self.assertIn("summary", res_what.json())


if __name__ == "__main__":
    unittest.main()


-- =============================================
-- 🟣 NIMMY — Migration 006: Memories
-- =============================================

CREATE TYPE memory_type AS ENUM ('fact', 'preference', 'habit', 'relationship', 'event', 'insight');
CREATE TYPE memory_source AS ENUM ('conversation', 'task', 'note', 'recording', 'manual');

CREATE TABLE IF NOT EXISTS memories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    memory_type     memory_type DEFAULT 'fact',
    source          memory_source DEFAULT 'conversation',
    source_id       UUID,                       -- Reference to originating record
    content         TEXT NOT NULL,               -- The memory content
    context         TEXT,                        -- Surrounding context
    importance      SMALLINT DEFAULT 5 CHECK (importance BETWEEN 1 AND 10),
    embedding       VECTOR(1536),                -- pgvector embedding for RAG
    is_active       BOOLEAN DEFAULT TRUE,
    last_accessed   TIMESTAMPTZ,
    access_count    INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_memories_user_id ON memories(user_id);
CREATE INDEX idx_memories_type ON memories(memory_type);
CREATE INDEX idx_memories_importance ON memories(importance DESC);

CREATE TRIGGER trg_memories_updated_at
    BEFORE UPDATE ON memories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

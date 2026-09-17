-- =========================================================
-- 🟣 NIMMY — Migration 014: Intelligence, Memory & Learning
-- =========================================================

CREATE TYPE memory_category AS ENUM (
    'profile',
    'preference',
    'goal',
    'project',
    'knowledge',
    'event',
    'idea',
    'correction'
);

CREATE TYPE confidence_tier AS ENUM (
    'very_high',   -- 1.00 Explicit user statement
    'high',        -- 0.95 User confirmed
    'medium',      -- 0.80 Repeated consistent pattern
    'imported',    -- 0.75 Synced calendar/integrations
    'inference',   -- 0.30 AI deduction (NEVER a fact)
    'unverified'   -- 0.10 Speculative context
);

CREATE TYPE provenance_source AS ENUM (
    'user_explicit',
    'user_confirmed',
    'user_correction',
    'user_note',
    'user_recording',
    'calendar',
    'task_database',
    'connected_service',
    'external_knowledge'
);

CREATE TYPE memory_status AS ENUM (
    'active',
    'superseded',
    'contradicted',
    'archived'
);

-- Enhanced Memory Items with Strict Provenance & Versioning
CREATE TABLE IF NOT EXISTS memory_items (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category            memory_category NOT NULL,
    content             TEXT NOT NULL,
    previous_value      TEXT,
    confidence_score    NUMERIC(3, 2) NOT NULL DEFAULT 0.95 CHECK (confidence_score BETWEEN 0.0 AND 1.0),
    confidence_tier     confidence_tier NOT NULL DEFAULT 'high',
    source_type         provenance_source NOT NULL DEFAULT 'user_explicit',
    source_id           UUID,
    source_name         TEXT,
    source_url          TEXT,
    user_confirmed      BOOLEAN DEFAULT TRUE,
    last_confirmed_at   TIMESTAMPTZ DEFAULT NOW(),
    status              memory_status DEFAULT 'active',
    superseded_by       UUID REFERENCES memory_items(id),
    tags                TEXT[] DEFAULT '{}',
    version_history     JSONB DEFAULT '[]'::jsonb,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_memory_items_user_category ON memory_items(user_id, category);
CREATE INDEX idx_memory_items_status ON memory_items(status);
CREATE INDEX idx_memory_items_confidence ON memory_items(confidence_score DESC);

-- Feedback Events (Thumbs Up / Down & Error Categorization)
CREATE TABLE IF NOT EXISTS feedback_events (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id          TEXT NOT NULL,
    message_id          TEXT,
    is_positive         BOOLEAN NOT NULL,
    error_category      TEXT CHECK (error_category IN ('wrong_information', 'wrong_action', 'wrong_interpretation', 'wrong_memory', 'other')),
    feedback_text       TEXT,
    suggested_correction TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_feedback_user ON feedback_events(user_id);
CREATE INDEX idx_feedback_category ON feedback_events(error_category);

-- Learned Correction Store (Tracks error patterns and candidate preferences)
CREATE TABLE IF NOT EXISTS corrections (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    original_data           TEXT NOT NULL,
    corrected_data          TEXT NOT NULL,
    context_entity          TEXT,
    repetition_count        INTEGER DEFAULT 1,
    is_candidate_preference BOOLEAN DEFAULT FALSE,
    user_confirmed_rule     BOOLEAN DEFAULT FALSE,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_corrections_user ON corrections(user_id);
CREATE INDEX idx_corrections_candidate ON corrections(is_candidate_preference);

-- Observable Action Audit Trail
CREATE TABLE IF NOT EXISTS audit_events (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type         TEXT NOT NULL,
    tool_name           TEXT NOT NULL,
    tool_arguments      JSONB DEFAULT '{}'::jsonb,
    execution_status    TEXT NOT NULL CHECK (execution_status IN ('success', 'failed', 'denied')),
    confidence_score    NUMERIC(3, 2),
    provenance          TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_user_action ON audit_events(user_id, action_type);
CREATE INDEX idx_audit_created ON audit_events(created_at DESC);

-- Automated triggers for updated_at
CREATE TRIGGER trg_memory_items_updated_at
    BEFORE UPDATE ON memory_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_corrections_updated_at
    BEFORE UPDATE ON corrections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

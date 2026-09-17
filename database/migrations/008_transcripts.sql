-- =============================================
-- 🟣 NIMMY — Migration 008: Transcripts
-- =============================================

CREATE TABLE IF NOT EXISTS transcripts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id    UUID NOT NULL REFERENCES recordings(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    full_text       TEXT NOT NULL,
    segments        JSONB DEFAULT '[]',          -- [{start_ms, end_ms, text, speaker}]
    language        VARCHAR(10) DEFAULT 'en',
    confidence      DECIMAL(4,3),                -- 0.000 - 1.000
    word_count      INTEGER,
    ai_summary      TEXT,
    ai_action_items JSONB DEFAULT '[]',          -- Extracted action items
    embedding       VECTOR(1536),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transcripts_recording ON transcripts(recording_id);
CREATE INDEX idx_transcripts_user_id ON transcripts(user_id);

CREATE TRIGGER trg_transcripts_updated_at
    BEFORE UPDATE ON transcripts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

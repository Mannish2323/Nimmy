-- =============================================
-- 🟣 NIMMY — Migration 007: Recordings
-- =============================================

CREATE TYPE recording_status AS ENUM ('recording', 'processing', 'transcribed', 'failed');

CREATE TABLE IF NOT EXISTS recordings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(300),
    file_url        TEXT NOT NULL,                -- Supabase Storage URL
    file_size_bytes BIGINT,
    duration_ms     INTEGER,
    format          VARCHAR(20) DEFAULT 'webm',
    status          recording_status DEFAULT 'recording',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_recordings_user_id ON recordings(user_id);
CREATE INDEX idx_recordings_status ON recordings(status);

CREATE TRIGGER trg_recordings_updated_at
    BEFORE UPDATE ON recordings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- =============================================
-- 🟣 NIMMY — Migration 005: Notes
-- =============================================

CREATE TABLE IF NOT EXISTS notes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id  UUID REFERENCES projects(id) ON DELETE SET NULL,
    title       VARCHAR(300),
    content     TEXT,                       -- Markdown content
    is_pinned   BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    color       VARCHAR(7),
    tags        TEXT[] DEFAULT '{}',
    ai_summary  TEXT,                       -- AI-generated summary
    ai_generated BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_project_id ON notes(project_id);
CREATE INDEX idx_notes_pinned ON notes(is_pinned) WHERE is_pinned = TRUE;

CREATE TRIGGER trg_notes_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

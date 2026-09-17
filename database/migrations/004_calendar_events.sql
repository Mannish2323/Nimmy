-- =============================================
-- 🟣 NIMMY — Migration 004: Calendar Events
-- =============================================

CREATE TYPE event_type AS ENUM ('meeting', 'reminder', 'deadline', 'personal', 'ai_scheduled');

CREATE TABLE IF NOT EXISTS calendar_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id         UUID REFERENCES tasks(id) ON DELETE SET NULL,
    title           VARCHAR(300) NOT NULL,
    description     TEXT,
    event_type      event_type DEFAULT 'personal',
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ,
    all_day         BOOLEAN DEFAULT FALSE,
    location        TEXT,
    color           VARCHAR(7),
    is_recurring    BOOLEAN DEFAULT FALSE,
    recurrence_rule VARCHAR(100),
    ai_generated    BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_calendar_user_id ON calendar_events(user_id);
CREATE INDEX idx_calendar_start ON calendar_events(start_time);
CREATE INDEX idx_calendar_task ON calendar_events(task_id);

CREATE TRIGGER trg_calendar_updated_at
    BEFORE UPDATE ON calendar_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

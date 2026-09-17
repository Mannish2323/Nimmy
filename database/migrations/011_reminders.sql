-- =============================================
-- 🟣 NIMMY — Migration 011: Reminders
-- =============================================

CREATE TYPE reminder_status AS ENUM ('pending', 'triggered', 'snoozed', 'dismissed');

CREATE TABLE IF NOT EXISTS reminders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id         UUID REFERENCES tasks(id) ON DELETE CASCADE,
    event_id        UUID REFERENCES calendar_events(id) ON DELETE CASCADE,
    title           VARCHAR(300) NOT NULL,
    message         TEXT,
    remind_at       TIMESTAMPTZ NOT NULL,
    status          reminder_status DEFAULT 'pending',
    is_recurring    BOOLEAN DEFAULT FALSE,
    recurrence_rule VARCHAR(100),
    snoozed_until   TIMESTAMPTZ,
    ai_generated    BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reminders_user_id ON reminders(user_id);
CREATE INDEX idx_reminders_remind_at ON reminders(remind_at);
CREATE INDEX idx_reminders_status ON reminders(status) WHERE status = 'pending';

CREATE TRIGGER trg_reminders_updated_at
    BEFORE UPDATE ON reminders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

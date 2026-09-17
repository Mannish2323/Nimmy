-- =============================================
-- 🟣 NIMMY — Migration 012: Automations
-- =============================================

CREATE TYPE automation_status AS ENUM ('active', 'paused', 'disabled', 'error');

CREATE TABLE IF NOT EXISTS automations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    trigger_type    VARCHAR(50) NOT NULL,        -- 'time', 'event', 'location', 'keyword'
    trigger_config  JSONB NOT NULL DEFAULT '{}', -- Trigger details
    action_type     VARCHAR(50) NOT NULL,        -- 'create_task', 'send_notification', 'run_ai'
    action_config   JSONB NOT NULL DEFAULT '{}', -- Action details
    status          automation_status DEFAULT 'active',
    run_count       INTEGER DEFAULT 0,
    last_run_at     TIMESTAMPTZ,
    ai_suggested    BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_automations_user_id ON automations(user_id);
CREATE INDEX idx_automations_status ON automations(status);

CREATE TRIGGER trg_automations_updated_at
    BEFORE UPDATE ON automations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

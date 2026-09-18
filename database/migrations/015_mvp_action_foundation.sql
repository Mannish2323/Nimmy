-- ============================================================
-- NIMMY — Migration 015: Canonical MVP action foundation
-- Voice/Text -> Tool -> Confirmation -> Data -> Audit
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Extend legacy enums only for the two canonical MVP tools.
ALTER TYPE memory_type ADD VALUE IF NOT EXISTS 'goal';
ALTER TYPE memory_type ADD VALUE IF NOT EXISTS 'project';
ALTER TYPE memory_type ADD VALUE IF NOT EXISTS 'person';
ALTER TYPE memory_type ADD VALUE IF NOT EXISTS 'decision';
ALTER TYPE memory_type ADD VALUE IF NOT EXISTS 'reminder_context';
ALTER TYPE memory_type ADD VALUE IF NOT EXISTS 'note';
ALTER TYPE memory_type ADD VALUE IF NOT EXISTS 'other';

ALTER TYPE memory_source ADD VALUE IF NOT EXISTS 'voice';
ALTER TYPE memory_source ADD VALUE IF NOT EXISTS 'text';
ALTER TYPE memory_source ADD VALUE IF NOT EXISTS 'system';

ALTER TABLE reminders
    ADD COLUMN IF NOT EXISTS request_id UUID,
    ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'UTC',
    ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'text',
    ADD COLUMN IF NOT EXISTS notification_scheduled BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE memories
    ADD COLUMN IF NOT EXISTS request_id UUID,
    ADD COLUMN IF NOT EXISTS source_reference TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reminders_user_request
    ON reminders(user_id, request_id)
    WHERE request_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_memories_user_request
    ON memories(user_id, request_id)
    WHERE request_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,
    tool_name   TEXT NOT NULL,
    request_id  UUID NOT NULL,
    source      TEXT NOT NULL CHECK (source IN ('voice', 'text', 'system')),
    status      TEXT NOT NULL CHECK (
        status IN ('proposed', 'confirmed', 'executed', 'failed', 'cancelled')
    ),
    metadata    JSONB NOT NULL DEFAULT '{}'::JSONB,
    error_code  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    executed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created
    ON audit_logs(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_request
    ON audit_logs(user_id, request_id);

CREATE TABLE IF NOT EXISTS user_preferences (
    id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                    UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    timezone                   TEXT NOT NULL DEFAULT 'UTC',
    language                   TEXT NOT NULL DEFAULT 'en-IN',
    voice_enabled              BOOLEAN NOT NULL DEFAULT TRUE,
    notifications_enabled      BOOLEAN NOT NULL DEFAULT FALSE,
    reduced_motion             BOOLEAN NOT NULL DEFAULT FALSE,
    confirmation_policy        JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER trg_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Compatibility names for the canonical product vocabulary. These views use
-- the underlying tables' RLS policies rather than bypassing them.
CREATE OR REPLACE VIEW profiles
WITH (security_invoker = TRUE)
AS
SELECT
    id,
    auth_id,
    email,
    display_name,
    avatar_url,
    timezone,
    language,
    onboarding_done,
    created_at,
    updated_at
FROM users;

CREATE OR REPLACE VIEW devices
WITH (security_invoker = TRUE)
AS
SELECT
    id,
    user_id,
    device_name,
    platform,
    device_id,
    push_token,
    app_version,
    os_version,
    is_active,
    last_seen_at,
    created_at
FROM device_sessions;

-- Central ownership predicate keeps policies readable and avoids clients
-- supplying an arbitrary user_id.
CREATE OR REPLACE FUNCTION owns_nimmy_user(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM users
        WHERE users.id = target_user_id
          AND users.auth_id = auth.uid()
    );
$$;

REVOKE ALL ON FUNCTION owns_nimmy_user(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION owns_nimmy_user(UUID) TO authenticated;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_select_own ON users;
CREATE POLICY users_select_own ON users
    FOR SELECT TO authenticated
    USING (auth_id = auth.uid());

DROP POLICY IF EXISTS users_insert_own ON users;
CREATE POLICY users_insert_own ON users
    FOR INSERT TO authenticated
    WITH CHECK (auth_id = auth.uid());

DROP POLICY IF EXISTS users_update_own ON users;
CREATE POLICY users_update_own ON users
    FOR UPDATE TO authenticated
    USING (auth_id = auth.uid())
    WITH CHECK (auth_id = auth.uid());

DROP POLICY IF EXISTS reminders_select_own ON reminders;
CREATE POLICY reminders_select_own ON reminders
    FOR SELECT TO authenticated
    USING (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS reminders_insert_own ON reminders;
CREATE POLICY reminders_insert_own ON reminders
    FOR INSERT TO authenticated
    WITH CHECK (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS reminders_update_own ON reminders;
CREATE POLICY reminders_update_own ON reminders
    FOR UPDATE TO authenticated
    USING (owns_nimmy_user(user_id))
    WITH CHECK (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS reminders_delete_own ON reminders;
CREATE POLICY reminders_delete_own ON reminders
    FOR DELETE TO authenticated
    USING (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS memories_select_own ON memories;
CREATE POLICY memories_select_own ON memories
    FOR SELECT TO authenticated
    USING (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS memories_insert_own ON memories;
CREATE POLICY memories_insert_own ON memories
    FOR INSERT TO authenticated
    WITH CHECK (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS memories_update_own ON memories;
CREATE POLICY memories_update_own ON memories
    FOR UPDATE TO authenticated
    USING (owns_nimmy_user(user_id))
    WITH CHECK (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS memories_delete_own ON memories;
CREATE POLICY memories_delete_own ON memories
    FOR DELETE TO authenticated
    USING (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS audit_logs_select_own ON audit_logs;
CREATE POLICY audit_logs_select_own ON audit_logs
    FOR SELECT TO authenticated
    USING (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS audit_logs_insert_own ON audit_logs;
CREATE POLICY audit_logs_insert_own ON audit_logs
    FOR INSERT TO authenticated
    WITH CHECK (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS preferences_all_own ON user_preferences;
CREATE POLICY preferences_all_own ON user_preferences
    FOR ALL TO authenticated
    USING (owns_nimmy_user(user_id))
    WITH CHECK (owns_nimmy_user(user_id));

DROP POLICY IF EXISTS devices_all_own ON device_sessions;
CREATE POLICY devices_all_own ON device_sessions
    FOR ALL TO authenticated
    USING (owns_nimmy_user(user_id))
    WITH CHECK (owns_nimmy_user(user_id));

-- Audit rows are append-only to authenticated clients. No UPDATE or DELETE
-- policy is intentionally created for audit_logs.

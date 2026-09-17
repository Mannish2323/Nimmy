-- =============================================
-- 🟣 NIMMY — Migration 013: Device Sessions
-- =============================================

CREATE TYPE device_platform AS ENUM ('android', 'ios', 'web', 'desktop');

CREATE TABLE IF NOT EXISTS device_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_name     VARCHAR(200),
    platform        device_platform NOT NULL,
    device_id       VARCHAR(255) NOT NULL,       -- Unique device identifier
    push_token      TEXT,                        -- FCM / APNs token
    app_version     VARCHAR(20),
    os_version      VARCHAR(50),
    is_active       BOOLEAN DEFAULT TRUE,
    last_seen_at    TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_device_user_id ON device_sessions(user_id);
CREATE INDEX idx_device_device_id ON device_sessions(device_id);
CREATE INDEX idx_device_active ON device_sessions(is_active) WHERE is_active = TRUE;

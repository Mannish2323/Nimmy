-- =============================================
-- 🟣 NIMMY — Migration 009: Messages
-- =============================================

CREATE TYPE message_role AS ENUM ('user', 'nimmy', 'system');
CREATE TYPE message_content_type AS ENUM ('text', 'voice', 'image', 'file', 'action');

CREATE TABLE IF NOT EXISTS messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,               -- Links to ai_conversations
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            message_role NOT NULL,
    content_type    message_content_type DEFAULT 'text',
    content         TEXT NOT NULL,
    metadata        JSONB DEFAULT '{}',          -- Tool calls, attachments, etc.
    tokens_used     INTEGER,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_user_id ON messages(user_id);
CREATE INDEX idx_messages_created ON messages(created_at);

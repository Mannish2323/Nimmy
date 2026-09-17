-- =============================================
-- 🟣 NIMMY — Migration 010: AI Conversations
-- =============================================

CREATE TABLE IF NOT EXISTS ai_conversations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(300),
    summary         TEXT,
    model_used      VARCHAR(100),
    total_tokens    INTEGER DEFAULT 0,
    message_count   INTEGER DEFAULT 0,
    is_archived     BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key to messages now that ai_conversations exists
ALTER TABLE messages
    ADD CONSTRAINT fk_messages_conversation
    FOREIGN KEY (conversation_id)
    REFERENCES ai_conversations(id)
    ON DELETE CASCADE;

CREATE INDEX idx_ai_conv_user_id ON ai_conversations(user_id);
CREATE INDEX idx_ai_conv_created ON ai_conversations(created_at DESC);

CREATE TRIGGER trg_ai_conv_updated_at
    BEFORE UPDATE ON ai_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

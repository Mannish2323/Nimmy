-- =============================================
-- 🟣 NIMMY — Migration 003: Tasks
-- =============================================

CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE task_status AS ENUM ('todo', 'in_progress', 'done', 'cancelled');

CREATE TABLE IF NOT EXISTS tasks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id      UUID REFERENCES projects(id) ON DELETE SET NULL,
    title           VARCHAR(500) NOT NULL,
    description     TEXT,
    priority        task_priority DEFAULT 'medium',
    status          task_status DEFAULT 'todo',
    due_date        TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    tags            TEXT[] DEFAULT '{}',
    is_recurring    BOOLEAN DEFAULT FALSE,
    recurrence_rule VARCHAR(100),            -- RRULE format
    parent_task_id  UUID REFERENCES tasks(id) ON DELETE CASCADE,  -- subtasks
    sort_order      INTEGER DEFAULT 0,
    ai_generated    BOOLEAN DEFAULT FALSE,   -- was this created by Nimmy AI?
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_parent ON tasks(parent_task_id);

CREATE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

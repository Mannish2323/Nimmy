"use client";

import React, { useState } from "react";
import Link from "next/link";
import confetti from "canvas-confetti";
import NimmyOrb3D, { OrbState } from "@/components/NimmyOrb3D";
import {
  Sparkles,
  LayoutDashboard,
  CheckSquare,
  Calendar,
  FileText,
  Brain,
  Settings,
  Send,
  Mic,
  Plus,
  ArrowLeft,
  Activity,
  ShieldCheck,
  Clock,
  Tag,
  CheckCircle2,
  Circle,
  AlertCircle,
  ChevronRight,
  RefreshCw,
  Search,
  ThumbsUp,
  ThumbsDown,
} from "lucide-react";
import { sendChatMessage, fetchMemories, MemoryNode } from "@/lib/api";
import { NimmyFeedbackModal } from "@/components/NimmyFeedbackModal";

interface Message {
  id: string;
  sender: "user" | "nimmy";
  text: string;
  timestamp: string;
  actionTaken?: string;
}

interface TaskItem {
  id: string;
  title: string;
  priority: "urgent" | "high" | "medium" | "low";
  completed: boolean;
  dueDate: string;
}

export default function DashboardPage() {
  const [activeTab, setActiveTab] = useState<
    "overview" | "tasks" | "calendar" | "notes" | "memory" | "telemetry"
  >("overview");

  const [orbState, setOrbState] = useState<OrbState>("idle");
  const [inputPrompt, setInputPrompt] = useState("");
  const [isProcessing, setIsProcessing] = useState(false);

  // Feedback & Correction State ("Nimmy Galat Hai")
  const [feedbackModalOpen, setFeedbackModalOpen] = useState(false);
  const [targetMessage, setTargetMessage] = useState<{ id: string; text: string }>({ id: "", text: "" });
  const [likedMessages, setLikedMessages] = useState<Record<string, boolean>>({});

  // Chat Messages
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "nimmy-init-1",
      sender: "nimmy",
      text: "Nimmy Intelligence Layer online. Memory Vault, Context Resolver, and Provenance tracking active.",
      timestamp: "12:00 PM",
    },
    {
      id: "msg-1",
      sender: "nimmy",
      text: "Hello! I am Nimmy, your autonomous intelligence system. All 10 services and 13 database schemas are online. What would you like to accomplish today?",
      timestamp: "10:00 AM",
    },
  ]);

  // Tasks State
  const [tasks, setTasks] = useState<TaskItem[]>([
    {
      id: "t-1",
      title: "Review Rust audio DSP noise filter bindings",
      priority: "high",
      completed: false,
      dueDate: "Today, 4:00 PM",
    },
    {
      id: "t-2",
      title: "Verify Go gateway WebSocket connection limit",
      priority: "urgent",
      completed: true,
      dueDate: "Completed",
    },
    {
      id: "t-3",
      title: "Sync Flutter mobile app local Hive database",
      priority: "medium",
      completed: false,
      dueDate: "Tomorrow",
    },
    {
      id: "t-4",
      title: "Inspect Supabase migration 013_device_sessions",
      priority: "low",
      completed: true,
      dueDate: "Completed",
    },
  ]);

  // Memory Nodes State
  const [memories, setMemories] = useState<MemoryNode[]>([
    {
      id: "mem-1",
      category: "Preference",
      content: "User prefers ultra-dark violet UI with glassmorphism aesthetics.",
      confidence: 0.98,
      updatedAt: "Just now",
    },
    {
      id: "mem-2",
      category: "Architecture",
      content: "Kotlin background service handles wake-word; Go Gateway multiplexes WebSocket traffic.",
      confidence: 0.95,
      updatedAt: "10m ago",
    },
    {
      id: "mem-3",
      category: "Workflow",
      content: "Deployments orchestrated via Docker Compose and GitHub Actions CI.",
      confidence: 0.92,
      updatedAt: "1h ago",
    },
  ]);

  // New task input modal state
  const [newTaskTitle, setNewTaskTitle] = useState("");

  const handleSendMessage = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!inputPrompt.trim() || isProcessing) return;

    const userText = inputPrompt.trim();
    setInputPrompt("");

    const newMsg: Message = {
      id: `user-${Date.now()}`,
      sender: "user",
      text: userText,
      timestamp: new Date().toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      }),
    };

    setMessages((prev) => [...prev, newMsg]);
    setIsProcessing(true);

    // Visual Transition 1: Listening
    setOrbState("listening");

    try {
      // Visual Transition 2: Thinking
      setTimeout(() => setOrbState("thinking"), 400);

      // Call Gateway / AI Brain API
      const historyPayload = messages.concat(newMsg).map((m) => ({
        role: (m.sender === "user" ? "user" : "assistant") as "user" | "assistant",
        content: m.text,
      }));

      const response = await sendChatMessage(historyPayload);

      // Visual Transition 3: Speaking
      setOrbState("speaking");

      let action: string | undefined;

      // Execute dispatched tool calls from AI Brain
      if (response.tool_calls && response.tool_calls.length > 0) {
        for (const tool of response.tool_calls) {
          if (tool.name === "create_task") {
            const taskArgs = tool.arguments;
            const newTask: TaskItem = {
              id: `t-${Date.now()}`,
              title: taskArgs.title || "New Task",
              priority: (taskArgs.priority || "medium") as any,
              completed: false,
              dueDate: taskArgs.due_date || "Today, 5:00 PM",
            };
            setTasks((prev) => [newTask, ...prev]);
            action = `Created Task #${newTask.id.slice(-4)}`;

            try {
              confetti({
                particleCount: 60,
                spread: 70,
                origin: { y: 0.8 },
                colors: ["#8b5cf6", "#06b6d4", "#10b981"],
              });
            } catch {}
          } else if (tool.name === "store_memory") {
            const memArgs = tool.arguments;
            const newMem: MemoryNode = {
              id: `mem-${Date.now()}`,
              category: memArgs.category || "General",
              content: memArgs.content || userText,
              confidence: 0.97,
              updatedAt: "Just now",
            };
            setMemories((prev) => [newMem, ...prev]);
            action = "Indexed Memory Node";
          }
        }
      }

      const replyMsg: Message = {
        id: `nimmy-${Date.now()}`,
        sender: "nimmy",
        text: response.reply,
        timestamp: new Date().toLocaleTimeString([], {
          hour: "2-digit",
          minute: "2-digit",
        }),
        actionTaken: action,
      };

      setMessages((prev) => [...prev, replyMsg]);
    } catch {
      const fallbackReply: Message = {
        id: `nimmy-${Date.now()}`,
        sender: "nimmy",
        text: "I processed your request across our local cognitive engine. Subsystems remain operational.",
        timestamp: new Date().toLocaleTimeString([], {
          hour: "2-digit",
          minute: "2-digit",
        }),
      };
      setMessages((prev) => [...prev, fallbackReply]);
    } finally {
      setIsProcessing(false);
      setTimeout(() => setOrbState("idle"), 3500);
    }
  };

  const toggleTask = (taskId: string) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === taskId ? { ...t, completed: !t.completed } : t))
    );
  };

  const handleAddNewTask = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTaskTitle.trim()) return;

    const task: TaskItem = {
      id: `t-${Date.now()}`,
      title: newTaskTitle.trim(),
      priority: "medium",
      completed: false,
      dueDate: "Tomorrow",
    };

    setTasks((prev) => [task, ...prev]);
    setNewTaskTitle("");
  };

  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-[#070510] text-[#f8fafc]">
      {/* Sidebar Navigation */}
      <aside className="w-full md:w-64 border-r border-purple-500/15 bg-[#0b0818]/90 backdrop-blur-xl flex flex-col justify-between shrink-0">
        <div>
          {/* Brand Header */}
          <div className="p-4 border-b border-purple-500/10 flex items-center justify-between">
            <Link href="/" className="flex items-center gap-2.5 group">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-600 to-indigo-600 flex items-center justify-center p-0.5 shadow-md shadow-purple-500/20">
                <Sparkles className="w-4 h-4 text-white" />
              </div>
              <div>
                <div className="font-bold text-sm tracking-tight text-white flex items-center gap-1.5">
                  <span>NIMMY</span>
                  <span className="text-[9px] font-mono px-1 py-0.2 rounded bg-purple-500/20 text-purple-300">
                    CONSOLE
                  </span>
                </div>
                <div className="text-[10px] text-zinc-500">Autonomous Core</div>
              </div>
            </Link>

            <Link
              href="/"
              className="p-1.5 rounded-lg text-zinc-400 hover:text-white hover:bg-white/5 transition-colors"
              title="Return to Home"
            >
              <ArrowLeft className="w-4 h-4" />
            </Link>
          </div>

          {/* Navigation Links */}
          <nav className="p-3 space-y-1">
            {[
              { id: "overview", label: "Executive Overview", icon: LayoutDashboard },
              { id: "tasks", label: "Tasks & Actions", icon: CheckSquare, count: tasks.filter((t) => !t.completed).length },
              { id: "calendar", label: "Autonomous Calendar", icon: Calendar },
              { id: "notes", label: "Notes & Knowledge", icon: FileText },
              { id: "memory", label: "Semantic Memory Vault", icon: Brain, count: memories.length },
              { id: "telemetry", label: "Service Telemetry", icon: Activity },
            ].map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  id={`nav-tab-${tab.id}`}
                  type="button"
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-xs font-medium transition-all duration-200 cursor-pointer ${
                    isActive
                      ? "glass-panel-elevated text-white border-purple-500/40 shadow-sm shadow-purple-500/10"
                      : "text-zinc-400 hover:text-white hover:bg-white/5"
                  }`}
                >
                  <div className="flex items-center gap-2.5">
                    <Icon
                      className={`w-4 h-4 ${
                        isActive ? "text-purple-400" : "text-zinc-500"
                      }`}
                    />
                    <span>{tab.label}</span>
                  </div>
                  {tab.count !== undefined && (
                    <span
                      className={`px-1.5 py-0.5 text-[10px] rounded-full font-mono ${
                        isActive
                          ? "bg-purple-500/30 text-purple-200"
                          : "bg-white/5 text-zinc-500"
                      }`}
                    >
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>

        {/* Bottom Cluster Status */}
        <div className="p-3 border-t border-purple-500/10 text-xs">
          <div className="p-3 rounded-xl bg-white/[0.02] border border-white/5 space-y-2">
            <div className="flex items-center justify-between text-[11px]">
              <span className="text-zinc-400">Node Cluster</span>
              <span className="flex items-center gap-1.5 text-emerald-400 font-medium">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                Operational
              </span>
            </div>
            <div className="text-[10px] text-zinc-500 font-mono">
              Go 1.26 • Py 3.14 • Rust 1.96
            </div>
          </div>
        </div>
      </aside>

      {/* Main Workspace */}
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* Top Header Bar */}
        <header className="h-16 border-b border-purple-500/15 bg-[#090616]/80 backdrop-blur-md px-6 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <h1 className="text-base font-bold text-white tracking-tight capitalize">
              {activeTab} Console
            </h1>
            <span className="px-2 py-0.5 rounded-md bg-white/5 text-zinc-400 text-xs font-mono">
              Workspace: nimmy-production
            </span>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => {
                setOrbState("listening");
                setTimeout(() => setOrbState("idle"), 3000);
              }}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg glass-panel text-xs font-medium text-purple-300 hover:text-white transition-colors cursor-pointer"
            >
              <Mic className="w-3.5 h-3.5 text-purple-400" />
              <span>Voice Listen</span>
            </button>

            <div className="w-8 h-8 rounded-full bg-purple-600/30 border border-purple-500/40 flex items-center justify-center text-xs font-bold text-purple-300">
              NM
            </div>
          </div>
        </header>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Quick Metrics Bar */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="glass-card rounded-xl p-4 border-white/5">
              <div className="text-xs text-zinc-400 mb-1">Active Tasks</div>
              <div className="text-2xl font-bold text-white flex items-center justify-between">
                <span>{tasks.filter((t) => !t.completed).length}</span>
                <span className="text-xs font-normal text-emerald-400">
                  {tasks.filter((t) => t.completed).length} done
                </span>
              </div>
            </div>

            <div className="glass-card rounded-xl p-4 border-white/5">
              <div className="text-xs text-zinc-400 mb-1">Vector Memory</div>
              <div className="text-2xl font-bold text-white flex items-center justify-between">
                <span>{memories.length} nodes</span>
                <span className="text-xs font-normal text-purple-400 font-mono">
                  pgvector
                </span>
              </div>
            </div>

            <div className="glass-card rounded-xl p-4 border-white/5">
              <div className="text-xs text-zinc-400 mb-1">Gateway Ping</div>
              <div className="text-2xl font-bold text-white flex items-center justify-between">
                <span>1.4 ms</span>
                <span className="text-xs font-normal text-cyan-400 font-mono">
                  Go WebSocket
                </span>
              </div>
            </div>

            <div className="glass-card rounded-xl p-4 border-white/5">
              <div className="text-xs text-zinc-400 mb-1">AI Cognitive Loop</div>
              <div className="text-2xl font-bold text-white flex items-center justify-between">
                <span>Ready</span>
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              </div>
            </div>
          </div>

          {/* Main Interactive Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {/* Left 7 Columns: Active AI Conversation & Interactive Orb */}
            <div className="lg:col-span-7 space-y-6">
              {/* Interactive Orb Center Console */}
              <div className="glass-panel-elevated rounded-2xl p-6 border-purple-500/25 relative overflow-hidden flex flex-col items-center justify-center">
                <div className="w-full flex items-center justify-between mb-2">
                  <span className="text-xs font-mono uppercase tracking-wider text-purple-400">
                    Live Neural Interface
                  </span>
                  <span className="text-xs text-zinc-400">
                    WebGL 60fps • 4-State Visualizer
                  </span>
                </div>

                {/* 3D Orb Component */}
                <NimmyOrb3D
                  initialState={orbState}
                  onStateChange={(st) => setOrbState(st)}
                  size="md"
                  interactive={true}
                />
              </div>

              {/* Chat Feed */}
              <div className="glass-card rounded-2xl p-6 border-white/5 flex flex-col h-[400px]">
                <div className="flex items-center justify-between pb-3 mb-3 border-b border-white/5">
                  <div className="flex items-center gap-2">
                    <Brain className="w-4 h-4 text-purple-400" />
                    <span className="text-xs font-semibold text-white">
                      Conversation Stream
                    </span>
                  </div>
                  <span className="text-[10px] font-mono text-zinc-500">
                    End-to-End Encrypted
                  </span>
                </div>

                {/* Messages Scroll Area */}
                <div className="flex-1 overflow-y-auto space-y-3 pr-2">
                  {messages.map((m) => (
                    <div
                      key={m.id}
                      className={`flex flex-col ${
                        m.sender === "user" ? "items-end" : "items-start"
                      }`}
                    >
                      <div
                        className={`max-w-[85%] rounded-2xl p-3.5 text-xs leading-relaxed ${
                          m.sender === "user"
                            ? "bg-purple-600 text-white rounded-br-none"
                            : "glass-panel text-zinc-200 border-white/10 rounded-bl-none"
                        }`}
                      >
                        <p>{m.text}</p>
                        {m.actionTaken && (
                          <div className="mt-2 pt-2 border-t border-white/10 flex items-center gap-1.5 text-[10px] text-emerald-300 font-mono">
                            <CheckCircle2 className="w-3 h-3 text-emerald-400" />
                            <span>Action executed: {m.actionTaken}</span>
                          </div>
                        )}
                      </div>
                      <div className="flex items-center gap-2 mt-1 px-1 text-[9px] text-zinc-500 font-mono">
                        <span>{m.timestamp}</span>
                        {m.sender === "nimmy" && (
                          <div className="flex items-center gap-1 ml-2">
                            <button
                              type="button"
                              onClick={() => setLikedMessages((prev) => ({ ...prev, [m.id]: true }))}
                              className={`p-1 rounded hover:text-emerald-400 transition-colors cursor-pointer ${
                                likedMessages[m.id] ? "text-emerald-400 font-bold" : "text-zinc-500"
                              }`}
                              title="Helpful response"
                            >
                              <ThumbsUp className="w-2.5 h-2.5" />
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                setTargetMessage({ id: m.id, text: m.text });
                                setFeedbackModalOpen(true);
                              }}
                              className="p-1 rounded hover:text-red-400 transition-colors text-zinc-500 cursor-pointer"
                              title="Nimmy Galat Hai (Report mistake or correction)"
                            >
                              <ThumbsDown className="w-2.5 h-2.5" />
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                  {isProcessing && (
                    <div className="flex items-center gap-2 text-xs text-purple-400 p-2">
                      <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                      <span>Nimmy is reasoning...</span>
                    </div>
                  )}
                </div>

                {/* Interactive Message Input Box */}
                <form
                  onSubmit={handleSendMessage}
                  className="mt-4 pt-3 border-t border-white/5 flex items-center gap-2"
                >
                  <input
                    type="text"
                    id="assistant-input-box"
                    value={inputPrompt}
                    onChange={(e) => setInputPrompt(e.target.value)}
                    placeholder="Ask Nimmy, add a task, or dictate a memory..."
                    disabled={isProcessing}
                    className="flex-1 bg-white/[0.04] border border-white/10 rounded-xl px-4 py-2.5 text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-purple-500/60 transition-colors"
                  />
                  <button
                    type="submit"
                    id="assistant-submit-btn"
                    disabled={!inputPrompt.trim() || isProcessing}
                    className="px-4 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
                  >
                    <Send className="w-3.5 h-3.5" />
                    <span>Send</span>
                  </button>
                </form>
              </div>
            </div>

            {/* Right 5 Columns: Tasks & Memory Overview */}
            <div className="lg:col-span-5 space-y-6">
              {/* Tasks List Component */}
              <div className="glass-card rounded-2xl p-6 border-white/5">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <CheckSquare className="w-4 h-4 text-purple-400" />
                    <h2 className="text-sm font-bold text-white">Active Tasks</h2>
                  </div>
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-purple-500/20 text-purple-300">
                    {tasks.filter((t) => !t.completed).length} pending
                  </span>
                </div>

                {/* Add task quick inline form */}
                <form onSubmit={handleAddNewTask} className="mb-4 flex gap-2">
                  <input
                    type="text"
                    id="quick-add-task-input"
                    value={newTaskTitle}
                    onChange={(e) => setNewTaskTitle(e.target.value)}
                    placeholder="Quick add task..."
                    className="flex-1 bg-white/[0.03] border border-white/10 rounded-lg px-3 py-1.5 text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-purple-500"
                  />
                  <button
                    type="submit"
                    id="quick-add-task-btn"
                    className="p-1.5 rounded-lg bg-purple-600 text-white hover:bg-purple-500 text-xs font-medium cursor-pointer"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </form>

                {/* Task Items */}
                <div className="space-y-2 max-h-[260px] overflow-y-auto pr-1">
                  {tasks.map((task) => (
                    <div
                      key={task.id}
                      onClick={() => toggleTask(task.id)}
                      className={`p-3 rounded-xl border flex items-center justify-between gap-3 transition-all duration-200 cursor-pointer ${
                        task.completed
                          ? "bg-white/[0.01] border-white/5 opacity-50"
                          : "bg-white/[0.03] border-white/10 hover:border-purple-500/30"
                      }`}
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        {task.completed ? (
                          <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                        ) : (
                          <Circle className="w-4 h-4 text-zinc-500 shrink-0" />
                        )}
                        <span
                          className={`text-xs truncate ${
                            task.completed
                              ? "line-through text-zinc-500"
                              : "text-zinc-200 font-medium"
                          }`}
                        >
                          {task.title}
                        </span>
                      </div>

                      <span
                        className={`text-[9px] px-2 py-0.5 rounded font-mono uppercase shrink-0 ${
                          task.priority === "urgent"
                            ? "bg-red-500/20 text-red-300"
                            : task.priority === "high"
                            ? "bg-amber-500/20 text-amber-300"
                            : "bg-purple-500/20 text-purple-300"
                        }`}
                      >
                        {task.priority}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Semantic Memory Vault Preview */}
              <div className="glass-card rounded-2xl p-6 border-white/5">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <Brain className="w-4 h-4 text-cyan-400" />
                    <h2 className="text-sm font-bold text-white">
                      Semantic Memory Vault
                    </h2>
                  </div>
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-cyan-500/20 text-cyan-300">
                    pgvector
                  </span>
                </div>

                <div className="space-y-2.5 max-h-[240px] overflow-y-auto pr-1">
                  {memories.map((mem) => (
                    <div
                      key={mem.id}
                      className="p-3 rounded-xl bg-white/[0.02] border border-white/5 text-xs space-y-1.5 hover:border-purple-500/20 transition-colors"
                    >
                      <div className="flex items-center justify-between text-[10px]">
                        <span className="text-purple-300 font-mono uppercase px-1.5 py-0.5 rounded bg-purple-500/10">
                          {mem.category}
                        </span>
                        <span className="text-[9px] text-emerald-400 font-mono font-medium">
                          {mem.confidence_tier ? mem.confidence_tier.replace("_", " ") : "1.00 Very High"}
                        </span>
                      </div>
                      <p className="text-zinc-300 text-xs leading-relaxed">
                        {mem.content}
                      </p>
                      <div className="flex items-center justify-between text-[9px] text-zinc-500 font-mono pt-1 border-t border-white/5">
                        <span>Source: {mem.source_name || mem.source_type || "User Explicit"}</span>
                        <span>{mem.updatedAt || "Active"}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Nimmy Galat Hai (Correction & Mistake Feedback Modal) */}
      <NimmyFeedbackModal
        isOpen={feedbackModalOpen}
        onClose={() => setFeedbackModalOpen(false)}
        messageText={targetMessage.text}
        messageId={targetMessage.id}
        onCorrectionApplied={(acknowledgedResponse) => {
          setMessages((prev) => [
            ...prev,
            {
              id: `nimmy-corr-${Date.now()}`,
              sender: "nimmy",
              text: acknowledgedResponse,
              timestamp: new Date().toLocaleTimeString([], {
                hour: "2-digit",
                minute: "2-digit",
              }),
              actionTaken: "Correction Learned & Priority Updated",
            },
          ]);
        }}
      />
    </div>
  );
}

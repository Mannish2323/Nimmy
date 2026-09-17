"use client";

import React, { useState } from "react";
import {
  Smartphone,
  Cpu,
  Globe,
  Palette,
  Eye,
  Activity,
  Brain,
  Zap,
  ShieldCheck,
  Database,
  Terminal,
  Layers,
  ChevronRight,
} from "lucide-react";

interface TechItem {
  id: string;
  name: string;
  category: string;
  role: string;
  whyThisLanguage: string;
  features: string[];
  color: string;
  bgGlow: string;
  icon: React.ComponentType<{ className?: string; style?: React.CSSProperties }>;
  status: "Active" | "Configured" | "Phase 2";
}

const TECH_STACK: TechItem[] = [
  {
    id: "dart",
    name: "Dart / Flutter",
    category: "Mobile Application",
    role: "Cross-Platform Mobile UI & Offline Experience",
    whyThisLanguage:
      "60fps hardware-accelerated Skia rendering, hot reload, and clean state isolation for Android & iOS.",
    features: [
      "Animated Nimmy 2D Orb",
      "Unified Task & Schedule Hub",
      "Local Hive offline cache",
      "Biometric secure vault",
    ],
    color: "#54C5F8",
    bgGlow: "rgba(84, 197, 248, 0.15)",
    icon: Smartphone,
    status: "Active",
  },
  {
    id: "kotlin",
    name: "Kotlin",
    category: "Android Native Core",
    role: "Deep Android OS Integration & Background Daemon",
    whyThisLanguage:
      "Direct access to Android Foreground Services, AudioRecord buffers, WorkManager, and hardware alarms.",
    features: [
      "24/7 Voice wake-word detection",
      "AudioRecord PCM streaming",
      "WorkManager background sync",
      "Direct app launcher intents",
    ],
    color: "#7F52FF",
    bgGlow: "rgba(127, 82, 255, 0.15)",
    icon: Cpu,
    status: "Configured",
  },
  {
    id: "nextjs",
    name: "Next.js / TypeScript",
    category: "Web Platform",
    role: "Full-Stack Web Dashboard & Admin Console",
    whyThisLanguage:
      "Turbopack-accelerated React Server Components, type-safe API routing, and instant SEO performance.",
    features: [
      "Executive AI Command Hub",
      "Realtime WebSocket feeds",
      "Device session management",
      "Analytics & Memory browser",
    ],
    color: "#38BDF8",
    bgGlow: "rgba(56, 189, 248, 0.15)",
    icon: Globe,
    status: "Active",
  },
  {
    id: "tailwind",
    name: "Tailwind CSS v4",
    category: "Design System",
    role: "Aesthetic Framework & Glassmorphism Tokens",
    whyThisLanguage:
      "Modern CSS-first @theme engine with zero runtime overhead and bespoke dark-mode tokens.",
    features: [
      "Curated cosmic violet palette",
      "Hardware-accelerated blurs",
      "Fluid responsive layout",
      "Micro-interaction tokens",
    ],
    color: "#38BDF8",
    bgGlow: "rgba(56, 189, 248, 0.15)",
    icon: Palette,
    status: "Active",
  },
  {
    id: "threejs",
    name: "Three.js / WebGL",
    category: "3D Graphics Engine",
    role: "Interactive 3D Hologram Orb & Particle Halo",
    whyThisLanguage:
      "Raw GPU WebGL shaders and quaternion mathematics for lifelike audio-reactive avatar feedback.",
    features: [
      "350+ ambient stellar particles",
      "Dual orbiting quantum rings",
      "Dynamic mouse parallax tilt",
      "4-state lighting transitions",
    ],
    color: "#C084FC",
    bgGlow: "rgba(192, 132, 252, 0.15)",
    icon: Eye,
    status: "Active",
  },
  {
    id: "framer",
    name: "Framer Motion",
    category: "Motion Design",
    role: "Fluid UI Physics & State Transitions",
    whyThisLanguage:
      "Spring-physics animation system preventing layout shifts and delivering tactile feedback.",
    features: [
      "Bento card hover physics",
      "Presence exit/enter flows",
      "Staggered list reveals",
      "Tactile button presses",
    ],
    color: "#EC4899",
    bgGlow: "rgba(236, 72, 153, 0.15)",
    icon: Activity,
    status: "Active",
  },
  {
    id: "python",
    name: "Python (FastAPI)",
    category: "Artificial Intelligence",
    role: "Cognitive AI Brain & Vector Semantic Memory",
    whyThisLanguage:
      "Ecosystem leader for LLM tool calling, Sentence-Transformers, and autonomous agent planning.",
    features: [
      "Gemini 2.5 / OpenAI agent loops",
      "Semantic memory vector indexing",
      "Autonomous tool dispatch",
      "Context compression pipeline",
    ],
    color: "#FCD34D",
    bgGlow: "rgba(252, 211, 77, 0.15)",
    icon: Brain,
    status: "Active",
  },
  {
    id: "go",
    name: "Go (Golang)",
    category: "Distributed Gateway",
    role: "High-Throughput API Gateway & WebSocket Multiplexer",
    whyThisLanguage:
      "Goroutine lightweight concurrency handling 50k+ persistent client connections with <2ms latency.",
    features: [
      "Sub-millisecond reverse proxy",
      "Bi-directional WebSocket hub",
      "Token bucket rate limiting",
      "JWT authentication guard",
    ],
    color: "#00ADD8",
    bgGlow: "rgba(0, 173, 216, 0.15)",
    icon: Zap,
    status: "Active",
  },
  {
    id: "rust",
    name: "Rust",
    category: "High-Performance Core",
    role: "Real-Time Audio DSP & Cryptographic Security",
    whyThisLanguage:
      "Zero-cost abstractions and memory safety without garbage collection pause times.",
    features: [
      "FFI export for mobile & gateway",
      "SIMD vector math routines",
      "Audio noise suppression filter",
      "Zero-allocation memory bounds",
    ],
    color: "#F97316",
    bgGlow: "rgba(249, 115, 22, 0.15)",
    icon: ShieldCheck,
    status: "Active",
  },
  {
    id: "postgres",
    name: "PostgreSQL & Supabase",
    category: "Relational & Vector Store",
    role: "Persistent Storage, RLS Security & pgvector",
    whyThisLanguage:
      "ACID transactional integrity, Row-Level Security, and combined relational + vector indexing.",
    features: [
      "13 comprehensive schema tables",
      "Automated updated_at triggers",
      "User row-level security",
      "Optimized foreign key indexes",
    ],
    color: "#336791",
    bgGlow: "rgba(51, 103, 145, 0.15)",
    icon: Database,
    status: "Active",
  },
];

export default function TechStackShowcase() {
  const [selectedId, setSelectedId] = useState<string>("nextjs");
  const activeItem =
    TECH_STACK.find((item) => item.id === selectedId) || TECH_STACK[0];

  return (
    <section id="tech-stack" className="py-24 relative overflow-hidden">
      {/* Background Decor */}
      <div className="absolute top-1/2 -left-48 w-96 h-96 rounded-full bg-purple-900/20 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-10 -right-48 w-96 h-96 rounded-full bg-cyan-900/20 blur-[120px] pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-300 text-xs font-semibold mb-4">
            <Layers className="w-3.5 h-3.5" />
            <span>Architecture Blueprint</span>
          </div>
          <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
            Unified 10-Language{" "}
            <span className="text-gradient-purple">Tech Matrix</span>
          </h2>
          <p className="text-base sm:text-lg text-zinc-400">
            Each language is hand-picked for what it does best. No bloated
            duplication — pure specialized performance from native Android
            kernels to WebGL GPU shaders.
          </p>
        </div>

        {/* Interactive Matrix Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Left Column: Language Selector Pills */}
          <div className="lg:col-span-5 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-1 gap-2.5">
            {TECH_STACK.map((item) => {
              const Icon = item.icon;
              const isSelected = item.id === selectedId;
              return (
                <button
                  key={item.id}
                  id={`tech-btn-${item.id}`}
                  type="button"
                  onClick={() => setSelectedId(item.id)}
                  className={`flex items-center justify-between p-3.5 rounded-xl border text-left transition-all duration-200 cursor-pointer ${
                    isSelected
                      ? "glass-panel-elevated border-purple-500/50 shadow-lg shadow-purple-500/15"
                      : "glass-card border-white/5 hover:border-white/20"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div
                      className="w-9 h-9 rounded-lg flex items-center justify-center transition-transform duration-200"
                      style={{
                        backgroundColor: isSelected
                          ? item.color + "25"
                          : "rgba(255,255,255,0.05)",
                      }}
                    >
                      <Icon
                        className="w-5 h-5"
                        style={{
                          color: isSelected ? item.color : "#a1a1aa",
                        }}
                      />
                    </div>
                    <div>
                      <div className="text-sm font-semibold text-white">
                        {item.name}
                      </div>
                      <div className="text-xs text-zinc-400">
                        {item.category}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <span
                      className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${
                        item.status === "Active"
                          ? "bg-emerald-500/15 text-emerald-400 border border-emerald-500/30"
                          : "bg-purple-500/15 text-purple-400 border border-purple-500/30"
                      }`}
                    >
                      {item.status}
                    </span>
                    <ChevronRight
                      className={`w-4 h-4 transition-transform duration-200 ${
                        isSelected
                          ? "text-purple-400 translate-x-1"
                          : "text-zinc-600"
                      }`}
                    />
                  </div>
                </button>
              );
            })}
          </div>

          {/* Right Column: Detailed Architectural Spec Card */}
          <div className="lg:col-span-7">
            <div className="glass-panel-elevated rounded-2xl p-6 sm:p-8 border border-purple-500/30 shadow-2xl relative overflow-hidden">
              {/* Dynamic Header */}
              <div className="flex items-start justify-between gap-4 mb-6">
                <div>
                  <span className="text-xs font-mono tracking-wider uppercase text-purple-400 mb-1 block">
                    {activeItem.category}
                  </span>
                  <h3 className="text-2xl sm:text-3xl font-bold text-white flex items-center gap-3">
                    {activeItem.name}
                  </h3>
                </div>
                <div
                  className="w-12 h-12 rounded-xl flex items-center justify-center"
                  style={{ backgroundColor: activeItem.color + "20" }}
                >
                  <activeItem.icon
                    className="w-6 h-6"
                    style={{ color: activeItem.color }}
                  />
                </div>
              </div>

              {/* Primary Role */}
              <div className="mb-6 p-4 rounded-xl bg-white/[0.03] border border-white/5">
                <span className="text-xs font-semibold text-zinc-400 uppercase tracking-wider block mb-1">
                  Assigned Architectural Role
                </span>
                <p className="text-base font-medium text-purple-200">
                  {activeItem.role}
                </p>
              </div>

              {/* Why This Language */}
              <div className="mb-6">
                <span className="text-xs font-semibold text-zinc-400 uppercase tracking-wider block mb-2">
                  Engineering Rationale
                </span>
                <p className="text-sm text-zinc-300 leading-relaxed">
                  {activeItem.whyThisLanguage}
                </p>
              </div>

              {/* Key Modules & Capabilities */}
              <div>
                <span className="text-xs font-semibold text-zinc-400 uppercase tracking-wider block mb-3">
                  Key Modules & Capabilities
                </span>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  {activeItem.features.map((feat, idx) => (
                    <div
                      key={idx}
                      className="flex items-center gap-2.5 p-3 rounded-lg bg-white/[0.02] border border-white/5"
                    >
                      <span
                        className="w-1.5 h-1.5 rounded-full"
                        style={{ backgroundColor: activeItem.color }}
                      />
                      <span className="text-xs text-zinc-200 font-medium">
                        {feat}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

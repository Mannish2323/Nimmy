"use client";

import React from "react";
import {
  Mic,
  Brain,
  CalendarCheck,
  Zap,
  Lock,
  Radio,
  Sparkles,
  ArrowUpRight,
} from "lucide-react";

interface FeatureCardProps {
  title: string;
  subtitle: string;
  description: string;
  icon: React.ComponentType<{ className?: string; style?: React.CSSProperties }>;
  tag: string;
  color: string;
  className?: string;
}

function FeatureCard({
  title,
  subtitle,
  description,
  icon: Icon,
  tag,
  color,
  className = "",
}: FeatureCardProps) {
  return (
    <div
      className={`glass-card rounded-2xl p-6 sm:p-8 flex flex-col justify-between relative overflow-hidden group ${className}`}
    >
      {/* Subtle hover gradient glow */}
      <div
        className="absolute top-0 right-0 w-36 h-36 rounded-full blur-[60px] opacity-0 group-hover:opacity-30 transition-opacity duration-500 pointer-events-none"
        style={{ backgroundColor: color }}
      />

      <div>
        <div className="flex items-center justify-between mb-6">
          <div
            className="w-12 h-12 rounded-xl flex items-center justify-center transition-transform duration-300 group-hover:scale-110"
            style={{ backgroundColor: `${color}18` }}
          >
            <Icon className="w-6 h-6" style={{ color }} />
          </div>
          <span className="text-[11px] font-mono uppercase tracking-wider px-2.5 py-1 rounded-full bg-white/5 text-zinc-400 border border-white/10">
            {tag}
          </span>
        </div>

        <h3 className="text-xl font-bold text-white mb-2 tracking-tight group-hover:text-purple-200 transition-colors">
          {title}
        </h3>
        <p className="text-xs font-medium text-purple-400/90 mb-3">{subtitle}</p>
        <p className="text-sm text-zinc-400 leading-relaxed">{description}</p>
      </div>

      <div className="mt-6 pt-4 border-t border-white/5 flex items-center justify-between text-xs text-zinc-400 group-hover:text-white transition-colors">
        <span className="font-medium">Explore subsystem</span>
        <ArrowUpRight className="w-4 h-4 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
      </div>
    </div>
  );
}

export default function FeatureGrid() {
  return (
    <section id="features" className="py-24 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-300 text-xs font-semibold mb-4">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Autonomous Intelligence</span>
          </div>
          <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
            Engineered for <span className="text-gradient">Real Action</span>
          </h2>
          <p className="text-base sm:text-lg text-zinc-400">
            Nimmy is not just a chat bubble. It orchestrates schedules, filters
            raw audio at the hardware level, remembers context across devices,
            and executes tasks proactively.
          </p>
        </div>

        {/* Bento Grid Layout */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Card 1: Realtime Voice */}
          <FeatureCard
            title="Real-Time Multimodal Voice"
            subtitle="Bidirectional Live Streaming"
            description="Ultra-low latency audio processing with voice activity detection (VAD) and immediate audio-reactive visual feedback via the 3D Hologram Orb."
            icon={Mic}
            tag="Audio / DSP"
            color="#06B6D4"
          />

          {/* Card 2: Semantic Memory */}
          <FeatureCard
            title="Persistent Semantic Memory"
            subtitle="Vector Knowledge Graph"
            description="Extracts key user preferences, past conversations, and scheduled commitments into indexed vector nodes, retrieved autonomously when relevant."
            icon={Brain}
            tag="AI Brain"
            color="#A855F7"
          />

          {/* Card 3: Autonomous Actions */}
          <FeatureCard
            title="Proactive Task Engine"
            subtitle="Context-Aware Scheduling"
            description="Turns conversational intent into calendar events, priority tasks, and smart reminders without tedious manual form entry."
            icon={CalendarCheck}
            tag="Productivity"
            color="#10B981"
          />

          {/* Card 4: Android OS Native Core */}
          <FeatureCard
            title="Android Background Services"
            subtitle="Kotlin Native Daemon"
            description="Always-available background listener, hardware alarm triggers, foreground services, and deep device API integrations."
            icon={Radio}
            tag="Kotlin Core"
            color="#8B5CF6"
          />

          {/* Card 5: High-Concurrency Gateway */}
          <FeatureCard
            title="Distributed Go Gateway"
            subtitle="Sub-2ms WebSocket Hub"
            description="Multi-threaded reverse proxy engineered in Go for ultra-fast client multiplexing, token-bucket rate limiting, and device session sync."
            icon={Zap}
            tag="Go Server"
            color="#00ADD8"
          />

          {/* Card 6: Privacy & RLS */}
          <FeatureCard
            title="Zero-Leak Security"
            subtitle="PostgreSQL RLS & FFI"
            description="Row-Level Security on all 13 database tables, end-to-end encrypted session tokens, and sandboxed memory execution."
            icon={Lock}
            tag="Security"
            color="#F59E0B"
          />
        </div>
      </div>
    </section>
  );
}

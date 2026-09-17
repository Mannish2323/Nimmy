"use client";

import React, { useState } from "react";
import Link from "next/link";
import Navbar from "@/components/Navbar";
import NimmyOrb3D, { OrbState } from "@/components/NimmyOrb3D";
import TechStackShowcase from "@/components/TechStackShowcase";
import FeatureGrid from "@/components/FeatureGrid";
import {
  Sparkles,
  ArrowRight,
  Shield,
  Zap,
  Terminal,
  Cpu,
  Layers,
  CheckCircle2,
  ExternalLink,
} from "lucide-react";

export default function Home() {
  const [orbState, setOrbState] = useState<OrbState>("idle");
  const [simulatedPrompt, setSimulatedPrompt] = useState<string | null>(null);

  const samplePrompts = [
    {
      text: "Nimmy, schedule high-priority sprint review tomorrow at 10 AM",
      state: "listening" as OrbState,
    },
    {
      text: "Recall conversation context regarding Supabase migration",
      state: "thinking" as OrbState,
    },
    {
      text: "Summarize active tasks and send notification to Android device",
      state: "speaking" as OrbState,
    },
  ];

  const handlePromptClick = (text: string, targetState: OrbState) => {
    setSimulatedPrompt(text);
    setOrbState(targetState);
  };

  return (
    <div className="relative min-h-screen flex flex-col bg-[#070510] text-[#f8fafc] overflow-hidden cyber-grid">
      <Navbar />

      {/* Hero Section */}
      <main className="flex-1">
        <section className="relative pt-12 pb-20 sm:pt-20 sm:pb-32 overflow-hidden">
          {/* Radial Top Glows */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] bg-gradient-to-b from-purple-600/20 via-violet-600/10 to-transparent blur-[120px] pointer-events-none -z-10" />

          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center max-w-4xl mx-auto mb-10">
              {/* Release Tag */}
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full glass-panel border border-purple-500/30 text-purple-300 text-xs font-semibold mb-6 shadow-sm shadow-purple-500/10">
                <span className="w-2 h-2 rounded-full bg-purple-400 animate-pulse" />
                <span>Nimmy Intelligence System • Multi-Platform Architecture</span>
              </div>

              {/* Main Headline */}
              <h1 className="text-4xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight text-white mb-6 leading-[1.1]">
                Your Autonomous{" "}
                <span className="text-gradient-purple">Multi-Language</span> AI
                Assistant
              </h1>

              {/* Subtitle */}
              <p className="text-base sm:text-xl text-zinc-300 max-w-2xl mx-auto leading-relaxed mb-8">
                Orchestrating Flutter mobile UI, native Kotlin OS daemons,
                Next.js web dashboards, Python cognitive brains, and high-speed
                Go & Rust services into a unified companion.
              </p>

              {/* CTA Action Buttons */}
              <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-12">
                <Link
                  href="/dashboard"
                  id="hero-launch-dashboard-btn"
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-xl text-sm font-semibold text-white bg-gradient-to-r from-purple-600 via-violet-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 shadow-xl shadow-purple-600/30 hover:shadow-purple-600/50 transition-all duration-200 cursor-pointer group"
                >
                  <span>Open Live Assistant Console</span>
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                </Link>

                <a
                  href="#tech-stack"
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-xl text-sm font-semibold text-zinc-300 glass-panel hover:bg-white/10 hover:text-white transition-all duration-200"
                >
                  <span>Explore 10-Language Matrix</span>
                </a>
              </div>
            </div>

            {/* Centerpiece: Three.js 3D Nimmy Orb */}
            <div className="relative max-w-2xl mx-auto flex flex-col items-center">
              <NimmyOrb3D
                initialState={orbState}
                onStateChange={(st) => setOrbState(st)}
                size="lg"
              />

              {/* Interactive Prompt Simulation Chips */}
              <div className="mt-8 w-full max-w-xl">
                <div className="text-center text-xs font-mono uppercase tracking-wider text-zinc-400 mb-3">
                  Click a prompt chip to trigger state transition
                </div>
                <div className="flex flex-col gap-2">
                  {samplePrompts.map((p, idx) => (
                    <button
                      key={idx}
                      id={`sample-prompt-chip-${idx}`}
                      type="button"
                      onClick={() => handlePromptClick(p.text, p.state)}
                      className={`text-left text-xs p-3 rounded-xl border transition-all duration-200 cursor-pointer flex items-center justify-between ${
                        simulatedPrompt === p.text
                          ? "glass-panel-elevated border-purple-500/60 text-white shadow-md shadow-purple-500/20"
                          : "glass-card border-white/5 text-zinc-300 hover:border-white/20 hover:text-white"
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <Sparkles className="w-3.5 h-3.5 text-purple-400 shrink-0" />
                        <span>&quot;{p.text}&quot;</span>
                      </div>
                      <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-white/10 text-zinc-400 shrink-0">
                        {p.state}
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Telemetry Metrics Bar */}
            <div className="mt-20 max-w-5xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="glass-card rounded-xl p-4 text-center border-white/5">
                <div className="text-2xl sm:text-3xl font-extrabold text-white mb-1">
                  10
                </div>
                <div className="text-xs text-zinc-400 font-medium">
                  Unified Languages
                </div>
              </div>
              <div className="glass-card rounded-xl p-4 text-center border-white/5">
                <div className="text-2xl sm:text-3xl font-extrabold text-white mb-1">
                  13
                </div>
                <div className="text-xs text-zinc-400 font-medium">
                  Relational DB Tables
                </div>
              </div>
              <div className="glass-card rounded-xl p-4 text-center border-white/5">
                <div className="text-2xl sm:text-3xl font-extrabold text-white mb-1">
                  &lt; 2ms
                </div>
                <div className="text-xs text-zinc-400 font-medium">
                  Go Gateway Latency
                </div>
              </div>
              <div className="glass-card rounded-xl p-4 text-center border-white/5">
                <div className="text-2xl sm:text-3xl font-extrabold text-white mb-1">
                  60 FPS
                </div>
                <div className="text-xs text-zinc-400 font-medium">
                  GPU WebGL Orb
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Feature Bento Grid */}
        <FeatureGrid />

        {/* 10-Language Tech Stack Matrix */}
        <TechStackShowcase />

        {/* Architecture Flow Section */}
        <section id="architecture" className="py-24 relative border-t border-purple-500/10">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center max-w-3xl mx-auto mb-16">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 text-purple-300 text-xs font-semibold mb-4">
                <Cpu className="w-3.5 h-3.5" />
                <span>System Topology</span>
              </div>
              <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
                How Nimmy <span className="text-gradient-purple">Executes</span>
              </h2>
              <p className="text-base sm:text-lg text-zinc-400">
                A clean separation of concerns ensuring zero single point of failure
                and instant sub-second response times.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="glass-panel-elevated rounded-2xl p-6 border-purple-500/30">
                <div className="text-xs font-mono text-purple-400 uppercase tracking-wider mb-2">
                  Layer 1 • Client Ingress
                </div>
                <h3 className="text-lg font-bold text-white mb-3">
                  Mobile & Web Interfaces
                </h3>
                <p className="text-xs text-zinc-400 leading-relaxed mb-4">
                  Flutter cross-platform client and Next.js Web console communicate
                  over secure bi-directional WebSockets, streaming user voice and
                  touch interactions to the cluster.
                </p>
                <div className="space-y-1.5 text-xs text-zinc-300">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>Flutter Dart 60fps UI</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>Kotlin Background Daemon</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>Next.js 16 Web Console</span>
                  </div>
                </div>
              </div>

              <div className="glass-panel-elevated rounded-2xl p-6 border-cyan-500/30">
                <div className="text-xs font-mono text-cyan-400 uppercase tracking-wider mb-2">
                  Layer 2 • Transport & Security
                </div>
                <h3 className="text-lg font-bold text-white mb-3">
                  Go Gateway & Rust DSP
                </h3>
                <p className="text-xs text-zinc-400 leading-relaxed mb-4">
                  Ultra-low latency multiplexing proxy written in Go handles token
                  auth, rate-limiting, and sends raw audio chunks to Rust for
                  high-speed SIMD noise suppression.
                </p>
                <div className="space-y-1.5 text-xs text-zinc-300">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>Goroutine WebSocket Multiplexer</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>Rust FFI Audio Noise Filter</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>JWT & Device Session Auth</span>
                  </div>
                </div>
              </div>

              <div className="glass-panel-elevated rounded-2xl p-6 border-indigo-500/30">
                <div className="text-xs font-mono text-indigo-400 uppercase tracking-wider mb-2">
                  Layer 3 • Cognition & Memory
                </div>
                <h3 className="text-lg font-bold text-white mb-3">
                  Python AI Brain & PostgreSQL
                </h3>
                <p className="text-xs text-zinc-400 leading-relaxed mb-4">
                  FastAPI service orchestrates multimodal Gemini/OpenAI tool calling,
                  queries pgvector semantic memory, and persists verified state across
                  all 13 PostgreSQL tables.
                </p>
                <div className="space-y-1.5 text-xs text-zinc-300">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>FastAPI LLM Agent Loops</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>pgvector Long-Term Embeddings</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>13 Normalized Schema Migrations</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-purple-500/10 bg-[#06040d] py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-purple-600/30 border border-purple-500/40 flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-purple-300" />
            </div>
            <div>
              <span className="font-bold text-sm text-white">NIMMY</span>
              <span className="text-xs text-zinc-500 ml-2">
                Autonomous Intelligence Platform
              </span>
            </div>
          </div>

          <div className="text-xs text-zinc-500 text-center sm:text-right">
            Connected to GitHub repository{" "}
            <a
              href="https://github.com/Mannish2323/nimmy"
              target="_blank"
              rel="noopener noreferrer"
              className="text-purple-400 hover:text-purple-300 underline inline-flex items-center gap-1"
            >
              <span>Mannish2323/nimmy</span>
              <ExternalLink className="w-3 h-3" />
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}

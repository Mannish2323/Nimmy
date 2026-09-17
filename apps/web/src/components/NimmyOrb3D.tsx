"use client";

import React, { useEffect, useRef, useState } from "react";
import * as THREE from "three";
import { Mic, Sparkles, BrainCircuit, Volume2, ShieldCheck } from "lucide-react";

export type OrbState = "idle" | "listening" | "thinking" | "speaking";

interface NimmyOrb3DProps {
  initialState?: OrbState;
  interactive?: boolean;
  size?: "sm" | "md" | "lg";
  className?: string;
  onStateChange?: (state: OrbState) => void;
}

const STATE_CONFIG: Record<
  OrbState,
  {
    label: string;
    subtext: string;
    coreColor: string;
    particleColor: string;
    glowColor: string;
    speed: number;
    pulseAmp: number;
    particleSpread: number;
    icon: React.ComponentType<{ className?: string; style?: React.CSSProperties }>;
  }
> = {
  idle: {
    label: "Awaiting Command",
    subtext: "Neural core synchronized",
    coreColor: "#8b5cf6",
    particleColor: "#c084fc",
    glowColor: "rgba(139, 92, 246, 0.4)",
    speed: 0.8,
    pulseAmp: 0.08,
    particleSpread: 2.2,
    icon: Sparkles,
  },
  listening: {
    label: "Listening...",
    subtext: "Audio DSP streaming at 48kHz",
    coreColor: "#06b6d4",
    particleColor: "#38bdf8",
    glowColor: "rgba(6, 182, 212, 0.5)",
    speed: 1.8,
    pulseAmp: 0.22,
    particleSpread: 2.6,
    icon: Mic,
  },
  thinking: {
    label: "Synthesizing Thought",
    subtext: "Vector memory lookup in progress",
    coreColor: "#f59e0b",
    particleColor: "#fbbf24",
    glowColor: "rgba(245, 158, 11, 0.5)",
    speed: 2.4,
    pulseAmp: 0.16,
    particleSpread: 2.8,
    icon: BrainCircuit,
  },
  speaking: {
    label: "Speaking",
    subtext: "Natural voice generation active",
    coreColor: "#10b981",
    particleColor: "#34d399",
    glowColor: "rgba(16, 185, 129, 0.5)",
    speed: 1.5,
    pulseAmp: 0.28,
    particleSpread: 2.5,
    icon: Volume2,
  },
};

export default function NimmyOrb3D({
  initialState = "idle",
  interactive = true,
  size = "lg",
  className = "",
  onStateChange,
}: NimmyOrb3DProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [currentState, setCurrentState] = useState<OrbState>(initialState);
  const stateRef = useRef<OrbState>(initialState);
  stateRef.current = currentState;

  // Track mouse coordinates for subtle parallax tilt
  const mouseRef = useRef({ x: 0, y: 0, targetX: 0, targetY: 0 });

  useEffect(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    let width = container.clientWidth || 400;
    let height = container.clientHeight || 400;

    // 1. Scene & Camera Setup
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
    camera.position.z = 5.5;

    // 2. WebGL Renderer
    const renderer = new THREE.WebGLRenderer({
      canvas,
      alpha: true,
      antialias: true,
      powerPreference: "high-performance",
    });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    // 3. Central Hologram Core (Outer Wireframe Icosahedron)
    const coreGeo = new THREE.IcosahedronGeometry(1.3, 3);
    const coreMat = new THREE.MeshStandardMaterial({
      color: new THREE.Color(STATE_CONFIG[currentState].coreColor),
      wireframe: true,
      transparent: true,
      opacity: 0.65,
      roughness: 0.2,
      metalness: 0.8,
    });
    const coreMesh = new THREE.Mesh(coreGeo, coreMat);
    scene.add(coreMesh);

    // 4. Inner Glowing Energy Core
    const innerGeo = new THREE.SphereGeometry(0.85, 32, 32);
    const innerMat = new THREE.MeshBasicMaterial({
      color: new THREE.Color(STATE_CONFIG[currentState].coreColor),
      transparent: true,
      opacity: 0.35,
    });
    const innerMesh = new THREE.Mesh(innerGeo, innerMat);
    scene.add(innerMesh);

    // 5. Orbiting Quantum Ring 1
    const ring1Geo = new THREE.TorusGeometry(1.9, 0.018, 16, 100);
    const ring1Mat = new THREE.MeshBasicMaterial({
      color: new THREE.Color(STATE_CONFIG[currentState].particleColor),
      transparent: true,
      opacity: 0.7,
    });
    const ring1Mesh = new THREE.Mesh(ring1Geo, ring1Mat);
    ring1Mesh.rotation.x = Math.PI / 3;
    scene.add(ring1Mesh);

    // 6. Orbiting Quantum Ring 2
    const ring2Geo = new THREE.TorusGeometry(2.15, 0.015, 16, 100);
    const ring2Mat = new THREE.MeshBasicMaterial({
      color: new THREE.Color(STATE_CONFIG[currentState].coreColor),
      transparent: true,
      opacity: 0.5,
    });
    const ring2Mesh = new THREE.Mesh(ring2Geo, ring2Mat);
    ring2Mesh.rotation.x = -Math.PI / 4;
    ring2Mesh.rotation.y = Math.PI / 6;
    scene.add(ring2Mesh);

    // 7. Ambient Floating Particle Cloud (350 points)
    const particleCount = 350;
    const particleGeo = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const scales = new Float32Array(particleCount);

    for (let i = 0; i < particleCount; i++) {
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(Math.random() * 2 - 1);
      const dist = 1.4 + Math.random() * 1.5;

      positions[i * 3] = dist * Math.sin(phi) * Math.cos(theta);
      positions[i * 3 + 1] = dist * Math.sin(phi) * Math.sin(theta);
      positions[i * 3 + 2] = dist * Math.cos(phi);

      scales[i] = Math.random() * 0.06 + 0.02;
    }

    particleGeo.setAttribute(
      "position",
      new THREE.BufferAttribute(positions, 3)
    );

    const particleMat = new THREE.PointsMaterial({
      color: new THREE.Color(STATE_CONFIG[currentState].particleColor),
      size: 0.045,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
    });
    const particleSystem = new THREE.Points(particleGeo, particleMat);
    scene.add(particleSystem);

    // 8. Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.8);
    scene.add(ambientLight);

    const pointLight = new THREE.PointLight(
      new THREE.Color(STATE_CONFIG[currentState].coreColor),
      3,
      10
    );
    pointLight.position.set(0, 0, 0);
    scene.add(pointLight);

    // Mouse Move Interaction
    const handleMouseMove = (e: MouseEvent) => {
      const rect = container.getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      const y = -(((e.clientY - rect.top) / rect.height) * 2 - 1);
      mouseRef.current.targetX = x * 0.4;
      mouseRef.current.targetY = y * 0.4;
    };

    window.addEventListener("mousemove", handleMouseMove);

    // Animation Loop
    let animationFrameId: number;
    let clock = new THREE.Clock();

    const animate = () => {
      animationFrameId = requestAnimationFrame(animate);
      const delta = clock.getDelta();
      const time = clock.getElapsedTime();

      const config = STATE_CONFIG[stateRef.current];
      const targetColor = new THREE.Color(config.coreColor);
      const targetParticleColor = new THREE.Color(config.particleColor);

      // Smooth color transitions
      coreMat.color.lerp(targetColor, 0.05);
      innerMat.color.lerp(targetColor, 0.05);
      ring1Mat.color.lerp(targetParticleColor, 0.05);
      ring2Mat.color.lerp(targetColor, 0.05);
      particleMat.color.lerp(targetParticleColor, 0.05);
      pointLight.color.lerp(targetColor, 0.05);

      // Mouse Parallax Lerping
      mouseRef.current.x +=
        (mouseRef.current.targetX - mouseRef.current.x) * 0.05;
      mouseRef.current.y +=
        (mouseRef.current.targetY - mouseRef.current.y) * 0.05;

      // Dynamic Rotations
      coreMesh.rotation.x += 0.003 * config.speed;
      coreMesh.rotation.y += 0.005 * config.speed;

      ring1Mesh.rotation.z += 0.008 * config.speed;
      ring2Mesh.rotation.z -= 0.006 * config.speed;

      particleSystem.rotation.y = time * 0.04 * config.speed;

      // Pulse Breathing Effect
      const pulse = 1 + Math.sin(time * 3 * config.speed) * config.pulseAmp;
      coreMesh.scale.set(pulse, pulse, pulse);
      innerMesh.scale.set(pulse * 0.95, pulse * 0.95, pulse * 0.95);

      // Tilt container group
      scene.rotation.y = mouseRef.current.x;
      scene.rotation.x = -mouseRef.current.y;

      renderer.render(scene, camera);
    };

    animate();

    // Resize Handler
    const handleResize = () => {
      if (!container || !renderer || !camera) return;
      width = container.clientWidth;
      height = container.clientHeight;
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      renderer.setSize(width, height);
    };

    const resizeObserver = new ResizeObserver(handleResize);
    resizeObserver.observe(container);

    return () => {
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener("mousemove", handleMouseMove);
      resizeObserver.disconnect();
      renderer.dispose();
      coreGeo.dispose();
      coreMat.dispose();
      innerGeo.dispose();
      innerMat.dispose();
      ring1Geo.dispose();
      ring1Mat.dispose();
      ring2Geo.dispose();
      ring2Mat.dispose();
      particleGeo.dispose();
      particleMat.dispose();
    };
  }, []);

  const handleStateClick = (state: OrbState) => {
    setCurrentState(state);
    if (onStateChange) onStateChange(state);
  };

  const config = STATE_CONFIG[currentState];
  const CurrentIcon = config.icon;

  const sizeClasses = {
    sm: "w-[240px] h-[240px]",
    md: "w-[340px] h-[340px]",
    lg: "w-[420px] h-[420px] md:w-[480px] md:h-[480px]",
  }[size];

  return (
    <div
      className={`relative flex flex-col items-center justify-center ${className}`}
    >
      {/* Dynamic Ambient Background Glow */}
      <div
        className="absolute w-72 h-72 rounded-full blur-[90px] transition-all duration-700 pointer-events-none opacity-45 -z-10"
        style={{ background: config.glowColor }}
      />

      {/* WebGL Canvas Container */}
      <div ref={containerRef} className={`relative ${sizeClasses} cursor-grab`}>
        <canvas ref={canvasRef} className="w-full h-full block" />
      </div>

      {/* Current State HUD Badge */}
      <div className="mt-2 flex items-center gap-2.5 px-4 py-2 rounded-full glass-panel border border-white/10 shadow-lg backdrop-blur-md">
        <span className="relative flex h-2.5 w-2.5">
          <span
            className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75"
            style={{ backgroundColor: config.coreColor }}
          />
          <span
            className="relative inline-flex rounded-full h-2.5 w-2.5"
            style={{ backgroundColor: config.coreColor }}
          />
        </span>
        <CurrentIcon className="w-4 h-4 text-white/80" />
        <div className="flex flex-col text-left">
          <span className="text-xs font-semibold tracking-wide text-white">
            {config.label}
          </span>
          <span className="text-[10px] text-zinc-400">{config.subtext}</span>
        </div>
      </div>

      {/* Audio Reactive Equalizer Bars */}
      <div className="mt-4 flex items-center justify-center gap-1.5 h-6">
        {[24, 48, 80, 56, 92, 64, 40, 72, 88, 32, 60, 44].map((height, i) => (
          <div
            key={i}
            className="w-1 rounded-full transition-all duration-300"
            style={{
              height:
                currentState === "idle"
                  ? `${Math.max(6, height * 0.2)}px`
                  : currentState === "speaking"
                  ? `${height * 0.9}px`
                  : `${height * 0.5}px`,
              backgroundColor: config.coreColor,
              opacity: currentState === "idle" ? 0.35 : 0.9,
            }}
          />
        ))}
      </div>

      {/* Interactive Mode Selector Buttons */}
      {interactive && (
        <div className="mt-6 flex flex-wrap items-center justify-center gap-2 px-3 py-1.5 rounded-2xl glass-panel border border-white/10">
          {(["idle", "listening", "thinking", "speaking"] as OrbState[]).map(
            (state) => {
              const item = STATE_CONFIG[state];
              const Icon = item.icon;
              const isSelected = currentState === state;
              return (
                <button
                  key={state}
                  id={`orb-state-btn-${state}`}
                  type="button"
                  onClick={() => handleStateClick(state)}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium transition-all duration-200 cursor-pointer ${
                    isSelected
                      ? "bg-white/15 text-white shadow-sm border border-white/20"
                      : "text-zinc-400 hover:text-white hover:bg-white/5"
                  }`}
                  style={{
                    borderColor: isSelected ? item.coreColor : undefined,
                  }}
                >
                  <Icon
                    className="w-3.5 h-3.5"
                    style={{ color: isSelected ? item.coreColor : undefined }}
                  />
                  <span className="capitalize">{state}</span>
                </button>
              );
            }
          )}
        </div>
      )}
    </div>
  );
}

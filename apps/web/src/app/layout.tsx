import type { Metadata, Viewport } from "next";
import "./globals.css";

export const viewport: Viewport = {
  themeColor: "#070510",
  width: "device-width",
  initialScale: 1,
};

export const metadata: Metadata = {
  title: "Nimmy — Autonomous Multi-Language AI Assistant",
  description:
    "Next-generation autonomous AI assistant built with a unified multi-language architecture: Flutter, Kotlin, Next.js, Three.js, Python FastAPI, Go Gateway, Rust DSP, and PostgreSQL.",
  keywords: [
    "Nimmy",
    "AI Assistant",
    "Autonomous Agent",
    "Flutter",
    "Next.js",
    "Three.js",
    "Python AI",
    "Go Gateway",
    "Rust DSP",
  ],
  authors: [{ name: "Nimmy Intelligence Systems" }],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-[#070510] text-[#f8fafc] font-sans antialiased selection:bg-purple-600 selection:text-white">
        {children}
      </body>
    </html>
  );
}

<div align="center">
  <h1>🟣 NIMMY</h1>
  <p><strong>Your Intelligent AI Assistant — Multi-Platform, Multi-Language</strong></p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white" alt="Kotlin" />
    <img src="https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js" />
    <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
    <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
    <img src="https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white" alt="Go" />
    <img src="https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white" alt="Rust" />
    <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
    <img src="https://img.shields.io/badge/Three.js-000000?style=for-the-badge&logo=three.js&logoColor=white" alt="Three.js" />
    <img src="https://img.shields.io/badge/Tailwind-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white" alt="Tailwind" />
  </p>
</div>

---

## ✨ What is Nimmy?

Nimmy is a **multi-platform AI assistant** that combines voice interaction, task management, intelligent memory, and smart scheduling into one seamless experience. Built with a **10-language tech stack**, each language serves a specific, fixed role — ensuring the right tool for every job.

## 🏗️ Architecture

```
                    🟣 NIMMY
                       │
        ┌──────────────┼──────────────┐
        │              │              │
      MOBILE          WEB           AI
        │              │              │
   Flutter/Dart   Next.js/TS      Python
        │              │          FastAPI
      Kotlin          CSS             │
        │          Tailwind           │
        │        Framer Motion        │
        │        Three.js             │
        │                              │
        └──────────────┬───────────────┘
                       │
                  API Gateway
                       │
             ┌─────────┼─────────┐
             │         │         │
           Rust        Go      Python
             │         │         │
        Performance  Services    AI
             │         │         │
             └─────────┼─────────┘
                       │
                 PostgreSQL
                   Supabase
```

## 🗂️ Project Structure

```
nimmy/
├── apps/
│   ├── mobile/          📱 Flutter + Dart (main app)
│   └── web/             🌐 Next.js + TypeScript (web dashboard)
├── services/
│   ├── ai-brain/        🧠 Python + FastAPI (AI backend)
│   ├── gateway/         🔵 Go (API gateway + WebSocket)
│   └── performance/     ⚡ Rust (high-performance modules)
├── database/
│   └── migrations/      🗄️ PostgreSQL schema (13 tables)
├── scripts/             🔐 Bash (setup, build, deploy)
└── .github/workflows/   🚀 CI/CD pipeline
```

## 🔥 Language Map

| Language | Fixed Role |
|---|---|
| **Dart** | Flutter mobile app UI |
| **Kotlin** | Android system integration |
| **TypeScript** | Web dashboard + API integration |
| **HTML/CSS/Tailwind** | Web UI structure + styling |
| **Python** | AI/ML brain (FastAPI) |
| **Go** | Backend infrastructure + gateway |
| **Rust** | High-performance native modules |
| **C++** | Low-level DSP (future) |
| **SQL** | PostgreSQL database schema |
| **Bash** | DevOps, CI/CD |

## 📱 Features

### Mobile App (Flutter)
- 🎨 Premium dark theme with Nimmy purple palette
- 🟣 Animated Nimmy orb with 6 states (idle, listening, thinking, speaking, recording, task complete)
- ✅ Tasks with priority, projects, and subtasks
- 📅 Calendar with events
- 📝 Notes with search and pinning
- 🧠 Memory — see what Nimmy remembers about you
- 🎤 Voice interaction with hold-to-talk
- ⚙️ Settings with AI model, voice, and privacy options

### Web Dashboard (Next.js)
- 🌐 Responsive web dashboard
- 🧊 3D Nimmy hologram (Three.js + React Three Fiber)
- ✨ Framer Motion animations
- 🎨 Tailwind CSS styling
- 📊 Analytics panel

### AI Brain (Python)
- 💬 Conversational AI
- 📝 Transcription pipeline
- 📋 Summarization
- 🧠 Memory extraction
- 🔍 RAG (Retrieval Augmented Generation)
- 🤖 AI agents
- 💡 Recommendations

## 🚀 Getting Started

```bash
# Clone
git clone https://github.com/Mannish2323/nimmy.git
cd nimmy

# Setup (requires Node.js, Python, Go, Rust)
bash scripts/setup.sh

# Run web dashboard
cd apps/web && npm run dev

# Run AI brain
cd services/ai-brain && uvicorn app.main:app --reload

# Run Go gateway
cd services/gateway && go run cmd/server/main.go
```

## 🛠️ Development

### Prerequisites
- Node.js 24+
- Python 3.14+
- Go 1.26+
- Rust 1.96+
- Flutter 3.x (for mobile)
- Docker (optional, for local services)

### Environment Variables
Create a `.env` file in the root:
```env
GEMINI_API_KEY=your_key_here
SUPABASE_URL=your_url_here
SUPABASE_KEY=your_key_here
```

## 📄 License

MIT

---

<div align="center">
  <p><strong>Built with ❤️ by the Nimmy Team</strong></p>
  <p>🟣 Har problem ke liye appropriate language 🟣</p>
</div>
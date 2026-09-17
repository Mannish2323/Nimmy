#!/bin/bash
# =============================================
# 🟣 NIMMY — Development Environment Setup
# =============================================

set -e

echo "🟣 Setting up Nimmy development environment..."
echo "================================================"

# Colors
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ---- Check required tools ----
echo -e "\n${PURPLE}📋 Checking required tools...${NC}"

check_tool() {
    if command -v $1 &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 found: $($1 --version 2>&1 | head -1)"
    else
        echo -e "  ${YELLOW}✗${NC} $1 not found — please install it"
    fi
}

check_tool node
check_tool npm
check_tool python
check_tool go
check_tool rustc
check_tool flutter
check_tool docker

# ---- Setup Next.js Web App ----
echo -e "\n${PURPLE}🌐 Setting up Next.js web app...${NC}"
if [ -d "apps/web/node_modules" ]; then
    echo "  Already installed. Skipping."
else
    cd apps/web && npm install && cd ../..
fi

# ---- Setup Python AI Brain ----
echo -e "\n${PURPLE}🧠 Setting up Python AI brain...${NC}"
if [ -d "services/ai-brain/venv" ]; then
    echo "  Virtual environment exists. Skipping."
else
    cd services/ai-brain
    python -m venv venv
    source venv/bin/activate || source venv/Scripts/activate
    pip install -r requirements.txt
    deactivate
    cd ../..
fi

# ---- Setup Go Gateway ----
echo -e "\n${PURPLE}🔵 Setting up Go gateway...${NC}"
cd services/gateway && go mod tidy 2>/dev/null && cd ../..

# ---- Setup Rust Performance ----
echo -e "\n${PURPLE}⚡ Setting up Rust performance module...${NC}"
cd services/performance && cargo check 2>/dev/null && cd ../..

# ---- Setup Flutter App ----
echo -e "\n${PURPLE}📱 Setting up Flutter mobile app...${NC}"
if command -v flutter &> /dev/null; then
    cd apps/mobile && flutter pub get && cd ../..
else
    echo "  Flutter not installed. Skipping mobile app setup."
fi

echo -e "\n${GREEN}✅ Nimmy development environment setup complete!${NC}"
echo -e "${PURPLE}🟣 Happy coding with Nimmy!${NC}"

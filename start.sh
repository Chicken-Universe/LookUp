#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    # Don't automatically delete venv, let the user decide
    if [ -d "venv" ]; then
        echo -e "${YELLOW}[CLEANUP]${NC} Virtual environment still exists at $(pwd)/venv"
        read -p "Remove virtual environment? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "venv"
            echo -e "${GREEN}[OK]${NC} Virtual environment removed."
        fi
    fi

    # Remove cache directories
    if find "$(pwd)" -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null; then
        echo -e "${GREEN}[CLEANUP]${NC} Python cache directories removed."
    fi
}

trap cleanup EXIT INT TERM

echo "======================================================="
echo "        LOOKUP AI AGENT SYSTEM LAUNCHER               "
echo "======================================================="
echo ""

# 1. CHECK PYTHON
echo -e "${GREEN}[1/4]${NC} Checking Python Installation and Version..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Python3 not found on your system!
    echo ""
    echo "TROUBLESHOOTING GUIDE:"
    echo "1. Install Python 3.11+ using:"
    echo "   - Homebrew (macOS): brew install python@3.11"
    echo "   - apt (Ubuntu/Debian): sudo apt install python3.11"
    echo "   - yum (CentOS/RHEL): sudo yum install python3.11"
    echo ""
    echo "2. After installation, reopen this file."
    echo ""
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.11"

if ! python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Python version is too old!
    echo ""
    echo "FOUND: Python $PYTHON_VERSION"
    echo "REQUIRED: Python 3.11 or newer"
    echo ""
    echo "Please upgrade Python from:"
    echo "   - Homebrew: brew install python@3.11"
    echo "   - apt: sudo apt install python3.11"
    echo ""
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Python $PYTHON_VERSION detected."
echo ""

# 2. CHECK OLLAMA COMMAND & SERVICE
echo -e "${GREEN}[2/4]${NC} Checking Ollama Installation..."

OLLAMA_BIN=""

# Check if ollama is in PATH
if command -v ollama &> /dev/null; then
    OLLAMA_BIN="ollama"
else
    # Check common installation locations
    if [ -f "$HOME/.ollama/bin/ollama" ]; then
        OLLAMA_BIN="$HOME/.ollama/bin/ollama"
    elif [ -f "/usr/local/bin/ollama" ]; then
        OLLAMA_BIN="/usr/local/bin/ollama"
    elif [ -f "/opt/ollama/bin/ollama" ]; then
        OLLAMA_BIN="/opt/ollama/bin/ollama"
    fi
fi

if [ -z "$OLLAMA_BIN" ]; then
    echo -e "${RED}[ERROR]${NC} Perintah 'ollama' belum terdeteksi."
    echo "Lokasi instalasi umum:"
    echo "   - macOS: /usr/local/bin/ollama"
    echo "   - Linux: /usr/local/bin/ollama atau /opt/ollama/bin/ollama"
    echo "   - User install: ~/.ollama/bin/ollama"
    echo ""
    echo "Jika Ollama BARU SAJA diinstal, silakan TUTUP terminal ini dan buka kembali."
    echo "Jika belum menginstal, unduh di: https://ollama.com/download"
    echo ""
    exit 1
fi

# Export OLLAMA_BIN for use later
export OLLAMA_BIN

# Check if Ollama service is running
echo -e "${GREEN}[2/4]${NC} Checking Ollama Service..."

if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${YELLOW}[WARNING]${NC} Ollama not running in background. Starting Ollama..."
    
    # Try to start Ollama
    if "$OLLAMA_BIN" serve > /dev/null 2>&1 &
    then
        # Wait for startup
        sleep 5
        
        # Verify it started
        RETRY_COUNT=0
        MAX_RETRIES=10
        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
                echo -e "${GREEN}[OK]${NC} Ollama Service started successfully."
                break
            fi
            sleep 1
            RETRY_COUNT=$((RETRY_COUNT + 1))
        done
        
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo -e "${RED}[ERROR]${NC} Ollama failed to start after $MAX_RETRIES seconds!"
            echo ""
            echo "Possible causes:"
            echo "1. Port 11434 is already in use by another application"
            echo "2. Ollama does not have permission"
            echo "3. File system full"
            echo ""
            echo "Solutions:"
            echo "1. Check if port 11434 is in use: lsof -i :11434"
            echo "2. Try running with sudo if needed"
            echo "3. Check disk space: df -h"
            echo ""
            exit 1
        fi
    else
        echo -e "${RED}[ERROR]${NC} Failed to start Ollama!"
        exit 1
    fi
else
    echo -e "${GREEN}[OK]${NC} Ollama Service already running."
fi
echo ""

# 3. PULL MODEL
echo -e "${GREEN}[3/4]${NC} Checking AI Model granite3-dense..."

if "$OLLAMA_BIN" pull granite3-dense; then
    echo -e "${GREEN}[OK]${NC} Model granite3-dense ready.
else
    echo -e "${YELLOW}[WARNING]${NC} Failed to pull model granite3-dense. Trying llama2..."
    if "$OLLAMA_BIN" pull llama2; then
        echo -e "${GREEN}[OK]${NC} Model llama2 used as fallback."
    else
        echo -e "${RED}[ERROR]${NC} Failed to pull any model!"
        exit 1
    fi
fi
echo ""

# 4. SETUP VIRTUAL ENVIRONMENT AND RUN SERVER
echo -e "${GREEN}[4/4]${NC} Preparing Python Environment..."

if [ ! -d "venv" ]; then
    echo "Creating Virtual Environment..."
    if ! python3 -m venv venv; then
        echo -e "${RED}[ERROR]${NC} Failed to create virtual environment!"
        echo ""
        echo "Possible causes:"
        echo "1. Disk space full"
        echo "2. No permission to create folder"
        echo "3. Python venv module not installed"
        echo ""
        echo "Solutions:"
        echo "1. Check disk space: df -h"
        echo "2. Try with sudo if needed"
        echo "3. Install venv: sudo apt install python3-venv"
        echo ""
        exit 1
    fi
else
    echo -e "${GREEN}[OK]${NC} Virtual environment already exists."
fi

# Activate virtual environment
source venv/bin/activate

# Check dependencies
if ! python3 -c "import importlib.util; import sys; sys.exit(0 if all(importlib.util.find_spec(name) for name in ['uvicorn','fastapi','pydantic','langchain_ollama','langchain_core']) else 1)" 2>/dev/null; then
    echo "Installing and checking dependencies..."
    if ! pip install -r backend/requirements.txt; then
        echo -e "${RED}[ERROR]${NC} Failed to install dependencies!"
        echo ""
        echo "Possible causes:"
        echo "1. Network connection is unstable"
        echo "2. PyPI is not accessible"
        echo "3. Disk space full"
        echo "4. Package not compatible with Python version"
        echo ""
        echo "Please check error message above and try again."
        exit 1
    fi
elif [ -d "backend/__pycache__" ]; then
    echo -e "${GREEN}[OK]${NC} Virtual environment and cache ready. Running application."
else
    echo "Installing and checking dependencies..."
    if ! pip install -r backend/requirements.txt; then
        echo -e "${RED}[ERROR]${NC} Failed to install dependencies!"
        exit 1
    fi
fi

echo ""
echo "======================================================="
echo " LOOKUP WEB SERVICE STARTED SUCCESSFULLY!            "
echo "======================================================="
echo " Browser will automatically open at localhost:8000    "
echo "======================================================="
echo ""

# Open browser (cross-platform)
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:8000 > /dev/null 2>&1 &  # Linux
elif command -v open > /dev/null; then
    open http://localhost:8000 > /dev/null 2>&1 &      # macOS
fi

# Run the application
python3 backend/main.py
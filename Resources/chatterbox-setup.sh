#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# ChatterBox TTS — One-Command Setup & Launch
# Installs everything if needed, then starts the server.
# Requires: Python 3.12+, git
# ─────────────────────────────────────────────────────────────

VENV_DIR="$HOME/chatterbox-env"
REPO_DIR="$HOME/chatterbox-tts-api"
PORT=4123

# ── Check if server is already running ──────────────────────
if lsof -iTCP:$PORT -sTCP:LISTEN &>/dev/null; then
    echo "ChatterBox is already running on port $PORT."
    echo "http://127.0.0.1:$PORT"
    exit 0
fi

echo "══════════════════════════════════════════════════════════"
echo "  ChatterBox TTS — Setup & Launch"
echo "══════════════════════════════════════════════════════════"
echo ""

# ── Step 1: Locate Python 3.12+ ─────────────────────────────
PYTHON=""
for candidate in python3.12 python3.13 python3.14 python3; do
    if command -v "$candidate" &>/dev/null; then
        version=$("$candidate" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 12 ]; then
            PYTHON="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3.12+ is required but not found."
    echo "Install via: brew install python@3.12"
    echo "Or download from https://www.python.org/downloads/"
    exit 1
fi

echo "[1/4] Python: $($PYTHON --version 2>&1)"

# ── Step 2: Create venv + install deps (skip if already done) ─
NEEDS_INSTALL=false

if [ ! -d "$VENV_DIR" ]; then
    echo "[2/4] Creating virtual environment ..."
    "$PYTHON" -m venv "$VENV_DIR"
    NEEDS_INSTALL=true
else
    echo "[2/4] Virtual environment exists"
fi

source "$VENV_DIR/bin/activate"

if [ "$NEEDS_INSTALL" = true ] || ! python -c "import chatterbox" &>/dev/null; then
    echo "     Installing dependencies (this may take a few minutes first time) ..."
    pip install --upgrade pip --quiet
    pip install torch torchaudio --quiet 2>&1 | tail -1 || true
    pip install chatterbox-tts --no-deps --quiet 2>&1 | tail -1 || true
    pip install numpy scipy soundfile encodec \
        transformers tokenizers safetensors huggingface-hub \
        conformer einops jaxtyping librosa audioread \
        resemble-enhance noisereduce --quiet 2>&1 | tail -1 || true
fi

# ── Step 3: Clone/update the API server ──────────────────────
if [ ! -d "$REPO_DIR" ]; then
    echo "[3/4] Cloning chatterbox-tts-api ..."
    git clone --quiet https://github.com/travisvn/chatterbox-tts-api.git "$REPO_DIR"
    NEEDS_INSTALL=true
else
    echo "[3/4] Server repo exists"
fi

if [ "$NEEDS_INSTALL" = true ] || ! python -c "import fastapi" &>/dev/null; then
    echo "     Installing server dependencies ..."
    pip install sse-starlette "uvicorn[standard]" python-multipart \
        python-dotenv pydub aiofiles fastapi psutil resemble-perth --quiet 2>&1 | tail -1 || true
fi

# ── Step 4: Launch the server ─────────────────────────────────
echo "[4/4] Starting ChatterBox TTS on http://127.0.0.1:$PORT ..."
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  Server starting — first launch downloads the TTS model"
echo "  (~1.5 GB). Subsequent launches are instant."
echo "══════════════════════════════════════════════════════════"
echo ""

cd "$REPO_DIR"
exec python main.py

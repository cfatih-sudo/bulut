#!/usr/bin/env bash
# Bulut'u macOS / Linux'ta baslatir
set -e
cd "$(dirname "$0")"
command -v ollama >/dev/null || { echo "Ollama bulunamadi. https://ollama.com adresinden kurun."; exit 1; }
MODEL="${BULUT_MODEL:-qwen2.5-coder:7b}"
ollama list | grep -q "$MODEL" || ollama pull "$MODEL"
(sleep 1; command -v xdg-open >/dev/null && xdg-open http://127.0.0.1:8765 || open http://127.0.0.1:8765) >/dev/null 2>&1 &
exec python3 bulut.py --model "$MODEL" "$@"

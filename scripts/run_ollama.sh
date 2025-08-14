#!/usr/bin/env bash
set -euo pipefail
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_KV_CACHE=1
export OLLAMA_KEEP_ALIVE=3600
export OLLAMA_FLASH_ATTENTION=1
if ! pgrep -f "ollama serve" >/dev/null; then
  nohup ollama serve > ~/ollama.log 2>&1 &
  echo "ollama serve started at :11434"
else
  echo "ollama serve already running"
fi

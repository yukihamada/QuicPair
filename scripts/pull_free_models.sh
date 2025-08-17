#!/bin/bash

# Pull free models for QuicPair Core version
echo "🚀 Pulling free models for QuicPair Core..."

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed. Please install Ollama first."
    echo "Visit: https://ollama.ai/download"
    exit 1
fi

# Free models available in Core version
FREE_MODELS=(
    "gemma3:270m"
    "smollm2:135m"
    "qwen3:1.7b"
)

echo "📥 Downloading free models..."

for MODEL in "${FREE_MODELS[@]}"; do
    echo ""
    echo "📦 Pulling $MODEL..."
    ollama pull "$MODEL"
    if [ $? -eq 0 ]; then
        echo "✅ $MODEL downloaded successfully"
    else
        echo "❌ Failed to download $MODEL"
    fi
done

echo ""
echo "🎉 All free models have been pulled!"
echo "You can now use these models in QuicPair Core version."
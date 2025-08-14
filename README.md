# QuicPair — “クラウドに送らないAI” P2Pトンネル

あなたの **Mac上LLM** を **iPhone** に **P2P直結**。**Private‑by‑Default**、**E2E暗号（Noise IK）**、**TTFT<150ms** を狙う低遅延設計。

- 使い方は `/docs/PRODUCT_SPEC.md` と `/docs/TECH_SPEC.md` を参照。
- 開発は `/CLAUDE.md` に従って進めます。

## クイックスタート（開発）
```bash
brew install ollama
ollama pull llama3.1:8b-instruct-q4_K_M
./scripts/run_ollama.sh

cd server && go mod tidy && go run .
# iOS: ios/LLMClient.swift をプロジェクトに追加して接続
```

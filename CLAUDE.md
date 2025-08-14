# CLAUDE.md — QuicPair 開発ガイド（Claude Code向け）

> **目的**: Claude Code（以下 _Claude_）が、このリポジトリで**安全・高速**に開発を進めるための**唯一の参照**。
> **常に守る不変条件**: _Private‑by‑Default_ / _Strict Local Mode_ / _E2E暗号_ / _TTFT最優先_。

## 0. プロダクト原則（Never break）
- **Private‑by‑Default**: 既定で**外部送信ゼロ**。解析・テレメトリは**明示ON**のみ。
- **Strict Local Mode（既定ON）**: LAN/Tailscale内のみ到達可。リレー時も**アプリ層E2EE必須**。
- **E2E Security**: WebRTC DTLS **+ Noise IK**（端末間の相互認証）。鍵は端末を出ない。
- **Latency First**: **TTFT < 150ms（p50）**を満たす実装・チューニングを優先。

## 1. リポ構成と責務
- `/server` : Go（pion/webrtc）。`/signaling/offer` と DataChannel `"llm"`、Ollama/他バックエンドへのストリーム中継。
- `/ios`    : iOSクライアント（Swift / GoogleWebRTC）。Offer→Answer→DataChannel→逐次受信。
- `/scripts`: 起動・計測・デプロイスクリプト。
- `/infra`  : Caddy(HTTPS/H3)/coturn/launchd のテンプレート。
- `/docs`   : プロダクト/技術仕様、セキュリティ、テスト計画、KPI、プライバシー。
- `/prompts`: Claude初期プロンプト/コードレビュー/マーケティング。
- `/marketing` : LP/アプリストア/メール/投稿文/βアンケート等。
- `/.github` : Issue/PRテンプレ・CI雛形。

## 2. 実装規約
- **言語/スタイル**: Go 1.22（`gofmt`/`govet`）、Swift 5+（SwiftFormat）。
- **分岐**: `main`（保護） / `feat/*` / `fix/*` / `chore/*`。
- **コミット**: Conventional Commits。例: `feat(ios): add TTFT meter`。
- **テスト**: 最低限のユニット + E2E疎通（直P2P/ TURN）。TTFTを出力するスモーク必須。
- **PR要件**:
  1. 仕様更新があれば `/docs` を同時更新
  2. `scripts/measure_ttft.*` の結果をPR本文に貼付（直P2P/ TURN各1回）
  3. セキュリティチェックリスト（`/prompts/security/checklist.md`）全項目YES
  4. `Strict Local Mode` を壊していないこと（差分で確認）

## 3. バックエンド切替（Model Adapter方針）
- 統一IF: `backend.Generate(stream...)` / `Embeddings` / `Tokenize`。
- 既定: **Ollama**（ローカル推論）。
- 拡張: **Open‑weight**（例：各社の公開ウェイト）への**持ち込み(BYOW)**を許容。MPS(Pytorch)・ONNX/CoreML のアダプタを順次実装。
- **注記**: 特定ベンダの名称・配布形態は**時点で変化**し得るため、実装は**“オープンウェイト一般”**として抽象化する。

## 4. セキュリティ不変条件（自動チェック化を推奨）
- DataChannel確立後に**必ず Noise IK** を実行し、相互認証のない平文運用を禁止。（開発中は `DEV_ALLOW_PLAINTEXT=1` の明示時のみ許可）
- 端末鍵は iOS: **Secure Enclave/Keychain**，macOS: **Keychain** に保存。
- ログは**メタのみ**（成功/失敗/RTT/TTFT）。**内容ペイロードは絶対にログしない**。
- `Strict Local Mode` 中は外部ソケット接続・DNS解決を抑止（ガードをテスト）。

## 5. パフォーマンス目標
- TTFT: **<150ms p50 / <250ms p90**（8B 4bit、ウォーム、短プロンプト）。
- トークン速度: 20–40 tok/s（M3/Pro想定）。
- 再接続（ICE Restart）< 500ms。

## 6. Claude 実行時プロンプト（短縮版）
> **役割**: QuicPairの主任エンジニア。`CLAUDE.md` と `/docs/TECH_SPEC.md` を厳守し、**プライバシー×低遅延**を最優先に開発する。影響の大きい変更は提案→設計→実装→テスト→ドキュメント更新まで一気通貫で行う。**外部送信/依存は追加しない**。成果は**diff**・**テスト結果**・**ドキュメント更新**の3点セットで提出せよ。

## 7. よくあるタスクの雛形
- 「Noise IKの有効化」: `server/noise.go` 実装 → `ios/` に鍵生成/QRペアリング追加 → E2Eバッジ表示 → E2Eテスト。
- 「TTFTメーター」: `server`/`ios` 双方で計測 → `scripts/measure_ttft.*` → PRに結果貼付。
- 「BYOW登録UI」: `~/.quicpair/models.yaml` に追記 → バックエンド自動選択 → ライセンス表記自動表示。

## 8. 変更を躊躇なく戻す条件（Revert Policy）
- プライバシー違反、E2E破壊、TTFT劣化(p50>200ms)は**即時リバート**。

— QuicPair Core Team

# TECH_SPEC — QuicPair

## 1. アーキテクチャ
- **Signaling (Go)**: `/signaling/offer`（HTTPS/WSS）。SDP交換のみ（短時間）。
- **NAT越え**: ICE（STUN必須、TURNはcoturn推奨）。
- **Data Plane**: WebRTC DataChannel（UDP/SCTP/DTLS）。
- **E2E**: DataChannel確立後、アプリ層で **Noise IK** を実施（端末相互認証 + 前方秘匿）。
- **LLM Backend**: 既定Ollama。将来は**オープンウェイト**向けアダプタ（MPS/ONNX）を追加。

## 2. データフロー
1) iOS → Signaling: Offer POST → Answer受領  
2) iOS ⇄ macOS: ICE → P2P接続（失敗時 TURN）  
3) DataChannel `"llm"` 確立 → **Noise IK** ハンドシェイク  
4) iOS → Mac: `{"op":"chat", ...}`  
5) Mac → iOS: `{"op":"delta", "content":"..."}` 逐次ストリーム

## 3. セキュリティ（要件）
- 鍵: Ed25519 デバイス鍵（iOS: Secure Enclave/Keychain, macOS: Keychain）。
- ログ: メタのみ（TTFT, 成功/失敗）。**ペイロードは一切保存しない**。
- Strict Local: 外部宛接続とDNS解決をガード（設定で禁止）。

## 4. パフォーマンス
- Metal最適化（llama.cpp/Ollama）。KVキャッシュ＆ウォーム。並列=1。
- トークン即時送出（チャンク小さめ）。ICE再試行・優先順最適化（Host→Srflx→Relay）。

## 5. モデルアダプタ
- `backend` 抽象: Generate/Embeddings/Tokenize。
- 実装順: `ollama` → `pytorch_mps` → `onnx_coreml`。

## 6. 計測
- TTFT計測: iOS/Server両端でタイムスタンプ、`scripts/measure_ttft.*` で集約。
- TURN依存率: ICE stateログの匿名集計。

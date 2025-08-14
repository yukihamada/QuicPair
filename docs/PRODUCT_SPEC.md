# PRODUCT_SPEC — QuicPair

## 1. ゴール
- **Mac上のローカルLLM**を**iPhone**から**P2P直結**で叩く。
- **プライバシー**（Private‑by‑Default / E2E）と**レイテンシ**（TTFT<150ms）を両立。

## 2. 主要機能（MVP→本気版）
- MVP: Tailscale経由でOllamaを直叩き + OpenWebUI（即利用）。
- 本気版: 独自シグナリング（Go）+ WebRTC DataChannel（UDP/DTLS）+ **Noise IK**（アプリ層E2EE）。
- Strict Local Mode（既定ON）/ Private Relay Mode（自前TURN/MASQUE）。
- BYOW: ユーザーの**オープンウェイト**（例: 各社の公開モデル）をローカル登録して実行。

## 3. ユーザージャーニー
1) MacにQuicPairサーバを起動（Ollama起動済み）。  
2) iPhoneでアプリ起動 → **QRペアリング**（端末鍵交換・Noise IK準備）。  
3) 接続ボタン → **E2E:ON / Strict Local** バッジ → **100ms級で初トークン**。  
4) TTFTスコアをSNSでシェア（任意）。

## 4. KPI
- North Star: **100ms体験セッション比率**（TTFT<150ms）。
- 補助: 接続成功率、TURN依存率、継続率D7、シェア画像生成率。

## 5. 非機能要件
- セキュリティ: E2E（Noise IK）、鍵は端末外に出さない。
- 可用性: TURNフォールバック時も>99%接続成功。  
- パフォーマンス: 再接続<500ms、トークン20–40 tok/s。

## 6. 競合差別化
- **クラウド往復ゼロ**で“速さ”を体験で証明。  
- **Strict Local**既定、**オープンウェイト持ち込み**により**所有感**と**拡張性**。

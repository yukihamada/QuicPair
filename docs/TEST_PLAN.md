# TEST_PLAN — QuicPair

## 1. 目的
- プライバシー/E2E/Strict Localを壊さずに**TTFT<150ms**を満たしているかを検証。

## 2. テスト層
- **Unit**: 文字列フレーミング/Noiseハンドシェイク/設定ガード。
- **Integration**: `/signaling/offer` → DataChannel → Ollamaプロキシ。
- **E2E（ネットワーク）**: 直P2P / TURN 経路の両方で疎通・TTFT計測。
- **App Store前**: プライバシー栄養ラベル、外部送信ガード、バックグラウンド挙動。

## 3. 計測手順（E2E）
1) `scripts/run_ollama.sh` でウォーム起動。  
2) サーバ `go run .`。  
3) iOSで接続→ `sendChat("ping")`。  
4) **TTFT**は iOS:送信時刻→最初の`delta`受信時刻 の差。p50/p90を出力。

## 4. 受け入れ基準（β）
- 直P2P: TTFT p50 < 150ms / p90 < 250ms  
- TURN:  +20〜60ms 上振れまで許容（地域次第）

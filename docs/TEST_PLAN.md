# TEST_PLAN — QuicPair

## 1. 目的
- プライバシー/E2E/Strict Localを壊さずに**TTFT<150ms**を満たしているかを検証。

## 2. テスト層
- **Unit**: 文字列フレーミング/Noiseハンドシェイク/設定ガード。
- **Integration**: `/signaling/offer` → DataChannel → Ollamaプロキシ。
- **E2E（ネットワーク）**: 直P2P / TURN 経路の両方で疎通・TTFT計測。
- **App Store前**: プライバシー栄養ラベル、外部送信ガード、バックグラウンド挙動。

## 3. 新規テストシナリオ

### 3.1 Noise IK E2E暗号化テスト
- **目的**: アプリケーション層E2E暗号化の動作確認
- **手順**:
  1. サーバー起動、公開鍵確認 (`curl http://localhost:8443/noise/pubkey`)
  2. iOS クライアント接続
  3. DataChannel確立後、Noise IKハンドシェイク自動実行を確認
  4. E2E確立メッセージ受信を確認
  5. チャットメッセージが暗号化されていることを確認（Wireshark等）
  6. DEV_ALLOW_PLAINTEXT=1での平文フォールバック動作確認

### 3.2 Strict Local Modeテスト
- **目的**: 外部ネットワークアクセス制限の動作確認
- **手順**:
  1. サーバー起動（既定でStrict Local Mode ON）
  2. ローカルネットワークからの接続成功を確認
  3. 外部IPからの接続が拒否されることを確認
  4. Ollama URLに外部URLを設定し、エラーになることを確認
  5. DISABLE_STRICT_LOCAL=1で制限解除されることを確認

### 3.3 TTFT自動計測テスト
- **目的**: パフォーマンス目標の達成確認
- **手順**:
  1. `scripts/measure_ttft.sh p2p 20` 実行（P2P、20回）
  2. p50 < 150ms、p90 < 250ms を確認
  3. `scripts/measure_ttft.sh turn 20` 実行（TURN経由）
  4. TURN経由でも妥当な遅延増加（+20-60ms）に収まることを確認
  5. ttft_results.json の自動生成を確認

## 4. 計測手順（E2E）
1) `scripts/run_ollama.sh` でウォーム起動。  
2) サーバ `go run .` または `scripts/measure_ttft.sh` 使用。  
3) iOSで接続→ `sendChat("Tell me a joke")`。  
4) **TTFT**は iOS:送信時刻→最初の`delta`受信時刻 の差。p50/p90を出力。

## 5. セキュリティテストチェックリスト
- [ ] Noise秘密鍵がKeychain外に漏洩しないこと
- [ ] ログに平文メッセージが出力されないこと
- [ ] E2E暗号化なしでの通信を検出・警告すること
- [ ] セッション切断時に暗号化状態がクリーンアップされること
- [ ] 不正なNoise handshakeメッセージでクラッシュしないこと

## 6. パフォーマンステストチェックリスト
- [ ] コールドスタートでのTTFT測定
- [ ] ウォームスタートでのTTFT測定
- [ ] 長時間接続後のTTFT劣化がないこと
- [ ] 暗号化オーバーヘッドが10ms以下であること
- [ ] 複数同時接続でのTTFT劣化が20%以内

## 7. 受け入れ基準（β）
- 直P2P: TTFT p50 < 150ms / p90 < 250ms  
- TURN:  +20〜60ms 上振れまで許容（地域次第）
- E2E暗号化: 100%のメッセージで有効
- Strict Local Mode: 外部接続0件（ログで確認）
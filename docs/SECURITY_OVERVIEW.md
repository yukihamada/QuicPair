# SECURITY_OVERVIEW — QuicPair

## 1. 脅威モデル
- ネットワーク盗聴 / 中間者 / リレー運営者 / 紛失端末 / 悪意クライアント。
- 対策: DTLS + **Noise IK**（相互認証）, アプリ層暗号, 鍵は端末外へ不出, ログ最小化。

## 2. Noise IK実装詳細

### 2.1 プロトコル仕様
- **Noise Framework**: Noise_IK_25519_ChaChaPoly_BLAKE2b
- **DH**: Curve25519 (X25519)
- **Cipher**: ChaCha20-Poly1305
- **Hash**: BLAKE2b

### 2.2 ハンドシェイクフロー
1. DataChannel確立後、サーバーが公開鍵を送信
2. クライアントがNoise IKハンドシェイクを開始（InitiatorとしてIKパターン）
3. サーバーが応答（Responder）
4. 両者がセッション鍵を導出、E2E暗号化確立

### 2.3 実装詳細
- **サーバー側** (`server/noise.go`):
  - Flynn/noise ライブラリ使用
  - Keychain (macOS) に秘密鍵保存
  - セッション管理とnonceカウンター
  - DEV_ALLOW_PLAINTEXT環境変数で開発時平文許可

- **iOS側** (`ios/NoiseManager.swift`):
  - CryptoKit使用（Curve25519, ChaCha20-Poly1305）
  - Keychain にkSecAttrAccessibleWhenUnlockedThisDeviceOnlyで保存
  - 将来的にSecure Enclave対応予定

### 2.4 メッセージフォーマット
```
[2-byte length][ciphertext + tag]
```
- nonceは64-bit カウンター（リトルエンディアン）
- 最大メッセージサイズ: 65535バイト

## 3. キー管理
- iOS: Keychain（将来Secure Enclave対応）。macOS: Keychain。
- 初回: QRペアリングで公開鍵交換 + デバイス名バインド（実装予定）。
- 失効: 端末側で鍵廃棄 & セッション削除。

## 4. Strict Local Mode（既定ON）

### 4.1 ネットワーク制限
- 許可される接続元:
  - Loopback (127.0.0.1, ::1)
  - Private networks (RFC1918: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
  - Link-local (169.254.0.0/16, fe80::/10)
  - Tailscale CGNAT (100.64.0.0/10)

### 4.2 実装詳細
- カスタムnet.Listenerで非ローカル接続を拒否
- HTTPミドルウェアでリクエスト元を検証
- Ollama等の外部サービスURLもローカルのみ許可
- DISABLE_STRICT_LOCAL=1で無効化可能（開発用）

## 5. ロギング/テレメトリ
- 既定OFF。ON時も**メタのみ**（TTFT/ICE状態/失敗コード）。
- 内容テキスト/音声等の**保存・送信は不可**。
- E2E暗号化状態のログ出力（セッション確立/破棄のみ）

## 6. セキュリティ監査項目
- [ ] Noise IKハンドシェイクの正常動作
- [ ] 鍵のKeychain保存と適切なアクセス制御
- [ ] Strict Local Modeでの外部接続ブロック
- [ ] ログに平文コンテンツが含まれないこと
- [ ] TTFT測定が暗号化処理をバイパスしないこと

## 7. 透明性
- 月次 Transparency Note（接続成功率/TURN依存率/障害）。個人情報は含めない。
- E2E暗号化の状態をUIで明示（実装予定）
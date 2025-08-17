# QuicPair — Private-by-Default なエッジAIチャット
**Mac ↔ iPhone を超低遅延で直結。推論はローカル優先、必要な時だけ世界へスケール。**  
*Private first. Scale when you choose.*

- 公式サイト（QuicPair）: https://github.com/yukihamada/QuicPair
- 連携プロジェクト（QUIVer）: https://github.com/yukihamada/quiver

---

## 目次
- [概要](#概要)
- [なぜQuicPairか](#なぜquicpairか)
- [主な機能](#主な機能)
- [アーキテクチャ](#アーキテクチャ)
- [インストール](#インストール)
- [使い方](#使い方)
- [料金プラン](#料金プラン)
- [セキュリティ設計](#セキュリティ設計)
- [QUIVerとの連携](#quiverとの連携)
- [ベンチマークと計測](#ベンチマークと計測)
- [よくある質問](#よくある質問)
- [開発と貢献](#開発と貢献)
- [ライセンス](#ライセンス)

---

## 概要
**QuicPair** は、Mac上のローカルLLM（Ollama/MLX 等）を **iPhoneから瞬時に使える**ようにする、プライバシー最優先のAIチャットアプリです。  
既定では**端末外に平文を出さず**、**E2E暗号化**されたP2P接続で会話します。負荷が大きい処理が必要な場合のみ、ユーザーの同意のもとで**QUIVer**ネットワークに**1タップでスケール**できます。

**このリポジトリには：**
- macOSアプリ / iOSアプリ（Swift/SwiftUI）
- Go製のWebRTCサーバ／Ollamaクライアント
- スクリプト・ドキュメント
が含まれます。

---

## なぜQuicPairか
- **プライバシー**：ローカル推論が前提。オフロード時も**明示の同意**と**暗号化**を徹底。
- **即応性**：ローカル＋ペアリングに最適化した設計で**TTFTの短縮**を追求。
- **シンプル**：QR ペアリング、1クリックで利用開始。モデル導入も自動化（Pro）。

---

## 主な機能
- **完全ローカル実行（既定）**：端末内で推論を完結。ゼロテレメトリ設計。
- **超低遅延P2P**：WebRTC データチャネル＋アプリ層E2E。
- **スコープスイッチ**：  
  - `Local Only`（既定）  
  - `My Devices (E2E)`（自分の他端末へ）  
  - `Global (QUIVer)`（ネットワークへオフロード）
- **モデル運用**：Ollama/MLX 連携、（Proで）**自動量子化・プリウォーム**。
- **データ分類プリセット**：機密/社内/公開可 で送信範囲を一目で管理。
- **計算レシート添付**：QUIVer使用時、**モデルID/重みハッシュ/署名/料金**を結果に添付。

---

## アーキテクチャ

```
[iPhone App]  ── Noise IK (X25519/AES-GCM/BLAKE2) ──  [Mac App]
    │                     アプリ層E2E                      │
    └────── WebRTC (DTLS-SRTP / DataChannel) ────────┘
                              │
                              └─ Ollama / MLX (Local LLM)
```

- **既定**はローカル完結。  
- ネットワーク条件により **STUN/TURN** を利用する場合があります（※内容はE2E暗号化されます）。  
- QUIVerへオフロードする場合は、**送信前に見積と同意**を得てから実行します。

---

## インストール
### 1) macOS（推奨）
1. **Releases** から最新の DMG を取得  
   https://github.com/yukihamada/QuicPair/releases  
2. DMG を開き、アプリを Applications にドラッグ
3. 初回起動で **Ollama** を自動セットアップ（または既存環境に接続）

> Homebrew Cask の提供がある場合は `brew install --cask quicpair` をご利用ください。

### 2) iOS
- App Store（準備中）  
- それまでは Xcode からビルド可能：`ios-app/` を開き実行（Cmd+R）

### 3) ソースからビルド
```bash
git clone https://github.com/yukihamada/QuicPair.git
cd QuicPair

# Go サーバ
cd server && go mod tidy && go run .

# macOS アプリ
open ../mac-app/QuicPair.xcodeproj
# iOS アプリ
open ../ios-app/QuicPair.xcodeproj
```

---

## 使い方
1. **Mac**でQuicPairを起動 → QRコード表示
2. **iPhone**でQuicPairを起動 → QRスキャンでペアリング
3. **チャット開始**（既定は `Local Only`）
4. 大きい処理が必要なら**スコープスイッチ**を `Global (QUIVer)` に → 見積を確認 → 同意 → 実行
5. 結果に**計算レシート**が自動添付（QUIVer経由時）

---

## 料金プラン

モデルそのものの"解放"では課金しません。時間短縮・運用省力・接続品質・保証に価値を集中させます。

**Core — 無料**
- ローカル推論：無制限（手動で任意モデル導入可）
- 端末ペアリング：1対1（Mac↔iPhone）
- E2E暗号化 / Strict Local Mode（既定ON）
- 手動モデル管理（自動量子化・プリウォームなし）
- BYO STUN/TURN（マネージドTURNは含まれません）

**Pro — ¥1,480/月（年払いあり）**
- Fast Start：プリウォーム＋キャッシュで初回応答を短縮
- Auto Optimizer：自動量子化 / 最適プロファイル選択（GGUF/MLX等）
- Model Packs：検証済みモデルのワンクリック導入・自動更新
- Multi‑Device：最大5台（Mac複数 / iPhone複数）
- Managed Connectivity：マネージドTURN/STUN（フェアユース）
- 優先サポート / 早期アクセス
- 毎月の QUIVer クレジット同梱（重い処理だけ安全に外出し）

**Team — ¥1,980/席/月（5席〜）**
- 管理コンソール / SSO・SAML / MDM 配布
- ポリシー（例：外部オフロード禁止 等）
- 私設TURN優先 / BYOK / 監査ログ（端末内）

**Enterprise — お問い合わせ**
- SLA / セキュリティレビュー / コンプライアンス対応
- プライベートマーケット / 私設メッシュ / カスタムモデル

---

## セキュリティ設計
- **多層暗号**：WebRTC（DTLS‑SRTP/データチャネル）＋ アプリ層E2E（Noise IK: X25519/AES‑GCM/BLAKE2）
- **鍵保護**：iOSは Secure Enclave、macOSは Keychain を使用
- **到達性**：NAT越えに STUN/TURN を利用する場合あり（内容はE2E暗号化）
- **ログポリシー**：ゼロテレメトリ（診断ログは端末内、会話内容は収集しません）
- **注意**：QUIVer へオフロードするジョブは、実行ノード上で復号が必要な場合があります。機密データは `Local Only` を推奨。

---

## QUIVerとの連携

QUIVer は「世界の遊休計算力を束ね、署名付きレシートで検証できる分散AIネットワーク」です。
QuicPair からは **スコープスイッチ**で `Global (QUIVer)` を選択するだけで、見積→同意→実行→レシート添付まで自動化されます。

```
[QuicPair iPhone/Mac] --(同意)--> [QUIVer Mesh]
                               ↘  署名付きレシート（モデルID/重みハッシュ/料金/署名）
```

- **QUIVer プロジェクト**: https://github.com/yukihamada/quiver
- **ネットワークサイト**: https://QUIVer.network（Explorer/Docs/Status など）

---

## ベンチマークと計測
- `./scripts/measure_ttft.sh` : 初回応答時間（TTFT）を測定
- `./scripts/test_e2e_encryption.sh` : E2E暗号化の往復テスト
- `GET /metrics/ttft` : 埋め込みメトリクス（例）
  ```json
  { "p50_ms": 145, "p90_ms": 230, "count": 1024 }
  ```

> 数値は 端末/モデル/量子化/温度で変動します。比較時は条件を明記してください。

---

## よくある質問

**Q. "端末から一切出ない"とありますが、本当に？**  
A. 既定はローカル完結です。NAT越え等で STUN/TURN を用いた中継が発生する場合もありますが、内容はE2E暗号化されています。QUIVerへオフロードする場合は明示同意が必要です。

**Q. どのモデルが使えますか？**  
A. Ollama/MLX 互換のオープンモデル全般。ProのModel Packで検証済みセットをワンクリック導入できます。

---

## 開発と貢献
- **ブランチ**: `feat/*`, `fix/*`（Conventional Commits を推奨）
- **事前チェック**: `./scripts/test_all.sh`, `./scripts/measure_ttft.sh`
- **セキュリティ**: `SECURITY.md` / `THREAT_MODEL.md` / `security.txt`
- **Issue / PR**: バグ報告・提案を歓迎します

---

## ライセンス

MIT License © 2025 QuicPair Project
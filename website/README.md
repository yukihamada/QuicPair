# QuicPair Website

QuicPairの公式ウェブサイトです。

## 構成

```
website/
├── index.html              # メインランディングページ
├── privacy-policy.html     # プライバシーポリシー
├── 404.html               # 404エラーページ
├── assets/                # アセット
│   ├── css/              # スタイルシート
│   ├── js/               # JavaScript
│   └── branding/         # ブランドアセット
├── downloads/            # ダウンロードファイル置き場
├── _redirects           # Cloudflare Pagesリダイレクト設定
└── wrangler.toml       # Cloudflare Workers設定
```

## デプロイ方法

### Cloudflare Pages（推奨）

1. Cloudflare Pagesで新しいプロジェクトを作成
2. GitHubリポジトリと接続
3. ビルド設定：
   - ビルドコマンド: （空欄）
   - ビルド出力ディレクトリ: `website`
4. デプロイ

### ローカルプレビュー

```bash
cd website
python3 -m http.server 8000
# または
npx serve .
```

## ダウンロードファイルの配置

1. Mac版: `/downloads/QuicPair-mac-latest.dmg`
2. iOS版: App Store URLを`index.html`内で更新

## カスタマイズ

### ブランドカラー変更

`/assets/css/styles.css`の`:root`セクションで変更：

```css
:root {
  --accent: #ea384c;  /* メインカラー */
}
```

### コンテンツ更新

- 日本語版: `index.html`を直接編集
- 英語版: 今後追加予定

## 注意事項

- ダウンロードファイルは`.gitignore`に追加してGitに含めない
- 大きなファイルはCloudflare R2やCDNを使用
- App Store URLは実際のものに置き換える

## ライセンス

MIT License
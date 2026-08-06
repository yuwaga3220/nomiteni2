# Hit'Ems

- テニスのトーナメント進行と結果予想を楽しめるWebアプリケーション
- 大会運営
- トーナメント進捗状況のリアルタイム確認
- トーナメントの予想

## 技術スタック

- 言語：Ruby 3.4
- フレームワーク：Rails 8.1
- DB：SQLite
- トーナメント描画用：Bracketry
- 認証：Google OAuth2

## セットアップ

```bash
bundle install
bin/rails db:migrate
bin/rails db:seed      # サンプルデータ投入（任意）
bin/rails server
```

## テスト

```bash
bin/rails test
```

## メモ

- トーナメントの状態管理（`status`: before / during / after）
　　開催前：予想の入力が可能。ブラケット編集は不可
　　開催中：大会オーナーが試合結果を入力可能
　　開催後：閲覧のみ

- bracketryの選定理由について記事書きたい。

## 次やること

大
- 選手アイコンの自動生成（適当にかっこいいアイコンの自動生成）
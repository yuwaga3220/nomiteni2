# Hit'Ems

- テニスのトーナメント進行と結果予想を楽しめるWebアプリケーション
- 大会運営
- トーナメント進捗状況のリアルタイム確認
- トーナメントの予想

## Tech Stack

- Language: Ruby 3.4
- Framework: Rails 8.1
- Database: SQLite (all environments, incl. production via a Kamal-managed persistent volume)
- Frontend: Bootstrap 3 (bootstrap-sass) + Sprockets + importmap + Turbo + Stimulus
- Bracket rendering: Bracketry (JS)
- Auth: bcrypt + session, Google OAuth2
- Real-time updates: Turbo Streams + Action Cable (Solid Cable)
- Images: Active Storage
- Pagination: will_paginate
- Jobs/Cache: Solid Queue, Solid Cache
- Deployment: Kamal (Docker)
- Testing: Minitest
- Lint/Security: RuboCop (rubocop-rails-omakase), Brakeman, bundler-audit

## Setup

```bash
bundle install
bin/rails db:migrate
bin/rails server
```

## こだわり

- トーナメント表の描画にBracketryを採用
- アプリアイコンはRikyuで生成した幾何学的なアイコン
- Turbo Streams + Action Cableによるリアルタイム更新機能

## Memo

- トーナメントの状態管理（`status`: before / during / after）
　　開催前：予想の入力が可能。ブラケット編集は不可
　　開催中：大会オーナーが試合結果を入力可能
　　開催後：閲覧のみ

- bracketryの選定理由について記事書きたい。

## Todo

大
- 選手アイコンの自動生成（適当にかっこいいアイコンの自動生成）

小
- 大会検索機能の追加
- AWSのコスト管理立ち上げ

予想締切のカウントダウン表示 — 大会が「開催前」の間、トップに「あとN時間で開催」のような表示。予想し忘れを防げる。

通知機能（メール/ブラウザ通知） — フォロー中の大会が始まった時、自分の予想が的中/不的中になった時に通知。今はページを開かないと分からない。

大会の検索・絞り込み（README のTodoにも記載あり） — 大会数が増えてきた時に地味に効く。

予想結果のSNSシェア — 「的中率◯%でした」を画像付きでX(旧Twitter)にシェアできるボタン。バイラル的な集客効果も期待できる。

プロフィールページでの成績推移 — 過去大会ごとの的中率をグラフ表示。今は単発の数字だけなので、継続利用のモチベーションになる。

PWA化（ホーム画面追加対応） — スマホでアプリっぽく開けるようにする。大会当日に会場でサッと開く用途と相性が良い。

オンボーディングツアー — 初回ログイン時に「ここで予想する」「ここでブラケットを見る」を軽く案内。初見だと機能が多くて迷いやすい。

試合結果のPDF・画像出力機能


----- 予想を同じセクションでぽちぽち押せるようにしたい。
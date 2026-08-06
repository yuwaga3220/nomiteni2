# Hit'Ems

- テニスのトーナメント進行と結果予想を楽しめるWebアプリケーション
- 大会運営
- トーナメント進捗状況のリアルタイム確認
- トーナメントの予想

## Tech Stack

- Language: Ruby 3.4
- Framework: Rails 8.1
- Database: SQLite (development/test) / PostgreSQL (production)
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
bin/rails db:seed      # サンプルデータ投入（任意）
bin/rails server
```

## Test

```bash
bin/rails test
```

## Memo

- トーナメントの状態管理（`status`: before / during / after）
　　開催前：予想の入力が可能。ブラケット編集は不可
　　開催中：大会オーナーが試合結果を入力可能
　　開催後：閲覧のみ

- bracketryの選定理由について記事書きたい。

## 次やること

大
- 選手アイコンの自動生成（適当にかっこいいアイコンの自動生成）
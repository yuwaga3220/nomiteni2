# CLAUDE.md

[Ruby on Rails チュートリアル](https://railstutorial.jp/)（第7版）のサンプルアプリケーション。Twitter 風のユーザー認証・マイクロポスト・フォロー機能を持つ Rails アプリ。

## 技術スタック

- Ruby 3.4.9 / Rails 8.1.3
- SQLite（開発・テスト）/ PostgreSQL（本番）
- テスト: Minitest（RSpec は使わない）
- フロント: Bootstrap 3（bootstrap-sass）+ Sprockets + importmap + Turbo + Stimulus
- 認証: `has_secure_password` + セッション（Devise 等は使わない）
- 画像: Active Storage

## よく使うコマンド

```bash
bin/rails server          # 開発サーバー起動
bin/rails test            # 全テスト
bin/rails test test/models/user_test.rb   # 単一ファイル
bin/rails db:migrate      # マイグレーション
bin/rubocop               # リント
bin/brakeman              # セキュリティスキャン
bundle exec guard         # ファイル変更時に関連テストを自動実行
```

変更後は必ず `bin/rails test` を実行し、関連ファイルがあればそのテストも通すこと。

## ディレクトリ構成（主要）

```
app/
  controllers/   # ApplicationController に logged_in_user フィルタ
  models/        # User, Micropost, Relationship
  views/         # ERB + Turbo Stream（relationships/ など）
  helpers/       # SessionsHelper（ログイン状態管理）
test/
  models/        # モデル単体テスト
  controllers/   # コントローラテスト
  integration/   # 統合テスト（ログイン・フォロー等）
  fixtures/      # users.yml, relationships.yml 等
config/routes.rb # ルーティング定義
```

## ドメインモデル

- **User**: 認証、アカウント有効化、パスワードリセット、フォロー/フォロワー、`feed`（自分＋フォロー中ユーザーのマイクロポスト）
- **Micropost**: ユーザーに属する投稿。Active Storage で画像添付可
- **Relationship**: `follower_id` / `followed_id` の自己参照 many-to-many

## コーディング規約

- **Rails Tutorial の書き方に合わせる**。教材と異なる gem やパターン（Devise, RSpec, Tailwind 等）は追加しない
- **変更は最小限**。依頼された範囲以外のファイルは触らない
- **2スペースインデント**、RuboCop Omakase に従う
- 既存コードの **日本語コメント・命名** に合わせる
- ビューは ERB。Ajax は **Turbo Stream** を優先（relationships の follow/unfollow 等）
- コントローラの before_action パターン、ヘルパーメソッド、fixture ベースのテストなど、既存実装を踏襲する

## テスト

- `test/test_helper.rb` の `log_in_as` でログイン状態を再現
- IntegrationTest: `log_in_as(user)` で POST login
- ActiveSupport::TestCase: `log_in_as(user)` で session 直接設定
- fixture のパスワードは `'password'`（users.yml 参照）
- 新機能には対応する Minitest を追加する（教材の流れに沿って）

## 禁止・注意

- 依頼されていない **git commit / push** をしない
- **credentials や secrets** を出力・コミットしない
- schema.rb を直接編集しない（マイグレーションを使う）
- 過剰なリファクタリングや抽象化をしない

## 参考

- 教材: https://railstutorial.jp/
- README.md にセットアップ手順あり

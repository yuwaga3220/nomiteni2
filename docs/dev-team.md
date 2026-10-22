# 開発チーム運用（複数 Claude 構成）

役割定義は `.claude/agents/`、タスクの入口は `.github/ISSUE_TEMPLATE/task.yml`。

## 役割

| 役割 | 担当 | 定義 |
|---|---|---|
| 事業責任者 | 人間 | 着手・マージ・デプロイ実行の判断（デプロイは手動実行） |
| プロマネ | Claude | `.claude/agents/pm.md` |
| コーディング | Claude | `.claude/agents/coder.md` |
| QA | Claude | `.claude/agents/qa.md` |
| デプロイ確認 | Claude | `.claude/agents/deployer.md`（手動デプロイ後の結果確認） |

## ラベル

| ラベル | 意味 | 付ける人 |
|---|---|---|
| `proposed` | PM が起票した、判断待ち | PM |
| `approved` | 着手 OK（ゲート①） | 事業責任者のみ |
| `in-progress` | コーダーが作業中 | コーダー |
| `qa-ok` / `qa-ng` | QA の判定 | QA |
| `needs-human` | 反復上限超過・要判断で停止中 | 各エージェント |

## 流れと人間のゲート

```
PM 起票(proposed) → [①approved] → Coder 実装・PR → QA 検証(qa-ok/qa-ng)
  qa-ng → Coder へ差し戻し（最大2回、超過は needs-human）
  qa-ok → [②マージ] → [③デプロイ実行（gh workflow run deploy.yml --ref main）] → Deployer が結果・スモークテスト確認
```

デプロイは手動実行のみで、main へのマージだけでは本番に反映されない。**デプロイ前に、含まれる PR の「本番への影響」欄（特にマイグレーション）を必ず確認する。**

## 自動化（GitHub Actions）

人間の判断は **①Issue に `approved` を付ける ②PR をマージする ③デプロイを実行する** の3つだけ。それ以外は Actions が進める。

| ワークフロー | きっかけ | やること |
|---|---|---|
| `pm.yml` | 毎週月曜 9:00 JST / 手動 | PM が課題を洗い出し `proposed` で起票（最大3件。判断待ちが5件以上ならスキップ） |
| `coder.yml` | `approved` ラベル（所有者が付けたときだけ） | Coder が実装して PR 作成 → `qa.yml` を起動。WIP 上限（5件）を超える間は待機し、PR マージ後に自動で次へ着手 |
| `qa.yml` | `coder.yml` から起動 | QA が検証して `qa-ok` / `qa-ng`。`qa-ng` は最大2回 `coder.yml` へ差し戻し、超えたら `needs-human` |
| `post-deploy.yml` | `Deploy` ワークフロー完了 | 結果とスモークテスト（トップ・ログイン画面）を、今回のデプロイに含まれる PR（前回の成功したデプロイ以降に入った PR）すべてに報告 |

- 停止・エスカレーション（`needs-human`、`qa-ok`、デプロイ失敗）時は、所有者へ `@` メンションで通知する
- 各エージェントの手順・制約は `.claude/agents/*.md` が正。ワークフローは「いつ起動するか」と権限の範囲だけを持つ
- PR のマージは、ワークフローの許可ツールに `gh pr merge` を含めないことで防いでいる。確実に防ぐなら `main` のブランチ保護（マージに所有者の承認を必須にする）も併用する

### 初回セットアップ（人間が1度だけ行う）

1. リポジトリの Secrets に `ANTHROPIC_API_KEY` を登録する
2. Settings → Actions → General → Workflow permissions で **「Allow GitHub Actions to create and approve pull requests」** を有効にする
3. `.claude/agents/` と `.github/` 配下の変更を main にマージする（ワークフローは main 上のものが使われる）

### 注意

- Actions（`GITHUB_TOKEN`）が作った PR では `ci.yml` が自動起動しない。代わりに QA が `bin/rails test` / `rubocop` / `brakeman` を実行する。デプロイ時の `deploy.yml` でもテストが走る
- 呼び出し回数 = API 利用料。`approved` の付け外しや `workflow_dispatch` の連打に注意する

## 手動での呼び出し例（Claude Code 上）

```
pm エージェントで課題を洗い出して
coder エージェントで Issue #12 を実装して
qa エージェントで PR #15 を QA して
デプロイを実行しました。deployer エージェントでデプロイ結果を確認して
```

## 運用ルール

- 同時に進める PR は最大5本（WIP 制限）
- セルフレビューは最大3回、QA 差し戻しは最大2回。超えたら `needs-human`
- PM は1回の実行で最大3件の起票

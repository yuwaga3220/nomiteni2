class Tournament < ApplicationRecord
  belongs_to :user
  has_many :participants, dependent: :destroy
  has_many :matches, dependent: :destroy
  default_scope -> { order(created_at: :desc) }
  enum :status, { before: 0, during: 1, after: 2 }
  validates :user_id, presence: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :venue, length: { maximum: 100 }, allow_blank: true

  # 予想を1件以上行っているユーザーを、獲得ポイントの合計が多い順に返す
  # 各ユーザーには total_points（獲得ポイント）、decided_predictions_count（結果が出た予想数）、
  # correct_predictions_count（的中数）が付与される
  def ranking
    User.joins(:predictions)
        .where(predictions: { match_id: matches.select(:id) })
        .group("users.id")
        .select(
          "users.*",
          "SUM(COALESCE(predictions.points, 0)) AS total_points",
          "COUNT(predictions.points) AS decided_predictions_count",
          "SUM(CASE WHEN predictions.points > 0 THEN 1 ELSE 0 END) AS correct_predictions_count"
        )
        .order(Arel.sql("total_points DESC"))
  end
end

class Tournament < ApplicationRecord
  belongs_to :user
  has_many :participants, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [ 500, 500 ]
    # 大会一覧カードの背景に使うモザイク（ぼかし）画像。極小サイズにし、CSS側で
    # image-rendering: pixelated を使って拡大表示することでモザイク効果を出す
    attachable.variant :mosaic, resize_to_fill: [ 128, 108 ]
  end
  default_scope -> { order(created_at: :desc) }
  enum :status, { before: 0, during: 1, after: 2 }
  validates :user_id, presence: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :venue, length: { maximum: 100 }, allow_blank: true
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png image/webp],
                                    message: "must be a valid image format" },
                    size:         { less_than: 5.megabytes,
                                    message:   "should be less than 5MB" }

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

  # 決勝（next_matchを持たない試合）の勝者を優勝者として返す（開催後でなければnil）
  def champion
    return nil unless after?
    matches.find_by(next_match_id: nil)&.winner
  end
end

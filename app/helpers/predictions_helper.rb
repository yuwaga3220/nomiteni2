module PredictionsHelper
  # 指定した試合から次の試合へ進むと予想される選手を返す
  # predictions: 自分の予想（match_idがキー）、feeders: 前の試合（[試合のid, 枠]がキー）
  def predicted_advancer(match, predictions, feeders)
    return nil if match.nil?
    return predictions[match.id]&.predicted_participant unless match.walkover?
    return match.winner if match.winner

    # 相手が未確定の不戦勝は、前の試合で予想した勝者がそのまま進む
    [ 1, 2 ].map { |slot|
      match.public_send("participant#{slot}") || predicted_advancer(feeders[[ match.id, slot ]], predictions, feeders)
    }.compact.find { |participant| !participant.withdrawn? }
  end
end

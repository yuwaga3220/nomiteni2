class PredictionsController < ApplicationController
  before_action :logged_in_user
  before_action :set_tournament

  def new
    @existing_predictions = current_user.predictions
                                        .where(match: @tournament.matches)
                                        .includes(:predicted_participant)
                                        .index_by(&:match_id)
    @all_matches = @tournament.matches.includes(:participant1, :participant2).to_a
    @feeder_matches = @all_matches.each_with_object({}) do |m, h|
      next unless m.next_match_id
      h[[ m.next_match_id, m.next_slot ]] = m
    end
    @ranking = @tournament.ranking unless @tournament.before?
    @prediction_log = prediction_log unless @tournament.before?

    # 波乱の勝者は、全試合が終了してから計算・表示する
    if @tournament.after?
      hit_rates = match_hit_rates(@prediction_log)
      @biggest_upset_match = biggest_upset_match(@prediction_log, hit_rates)
    end
  end

  def create
    unless @tournament.before?
      flash[:danger] = "開催前以外は予想を入力できません"
      redirect_to new_tournament_prediction_path(@tournament) and return
    end
    match = @tournament.matches.find(params[:match_id])
    Prediction.transaction do
      current_user.predictions.find_or_initialize_by(match: match)
                  .update!(predicted_participant_id: params[:participant_id])
      delete_downstream_predictions(match)
    end
    redirect_to new_tournament_prediction_path(@tournament)
  end

  private

  # 終了した試合に対する全員の予想結果を、新しい順に並べて返す
  def prediction_log
    Prediction.where(match: @tournament.matches.finished)
              .includes(:user, :predicted_participant, match: [ :participant1, :participant2, :winner ])
              .order(updated_at: :desc)
  end

  # 試合ごとに、全ユーザーの予想のうち何%が的中したかを返す
  def match_hit_rates(predictions)
    predictions.group_by(&:match_id).transform_values do |preds|
      correct = preds.count { |p| p.predicted_participant_id == p.match.winner_id }
      { correct: correct, total: preds.size, rate: (correct.to_f / preds.size * 100).round }
    end
  end

  # 全ユーザーの予想の的中率が最も低かった試合（＝最大の波乱）を返す
  def biggest_upset_match(predictions, hit_rates)
    return nil if hit_rates.blank?
    lowest_match_id = hit_rates.min_by { |_, rate| rate[:rate] }&.first
    predictions.find { |p| p.match_id == lowest_match_id }&.match
  end

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def delete_downstream_predictions(match)
    return unless match.next_match_id
    next_match = @tournament.matches.find_by(id: match.next_match_id)
    return unless next_match
    current_user.predictions.where(match: next_match).destroy_all
    delete_downstream_predictions(next_match)
  end
end

class PredictionsController < ApplicationController
  before_action :logged_in_user
  before_action :set_tournament

  def new
    return if block_unless_tournament_accessible(@tournament)

    set_bracket
    @ranking = @tournament.ranking unless @tournament.before?
    @prediction_log = prediction_log unless @tournament.before?

    # 波乱の勝者・最優秀予想者は、全試合が終了してから計算・表示する
    # 的中率は全ユーザーの予想で集計する（ログ表示用の@prediction_logとは分ける）
    if @tournament.after?
      finished_predictions = all_finished_predictions
      hit_rates = match_hit_rates(finished_predictions)
      @biggest_upset_match = biggest_upset_match(finished_predictions, hit_rates)
      @best_predictor = @tournament.best_predictor
    end
  end

  def create
    return if block_unless_tournament_accessible(@tournament)

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
    respond_to do |format|
      format.html { redirect_to new_tournament_prediction_path(@tournament) }
      # ブラケット部分だけを差し替え、投票前のスクロール位置を維持する
      format.turbo_stream { set_bracket }
    end
  end

  private

  # 予想ブラケットの描画に必要なデータを用意する
  def set_bracket
    @existing_predictions = current_user.predictions
                                        .where(match: @tournament.matches)
                                        .includes(:predicted_participant)
                                        .index_by(&:match_id)
    @all_matches = @tournament.matches.includes(:participant1, :participant2).to_a
    @feeder_matches = @all_matches.each_with_object({}) do |m, h|
      next unless m.next_match_id
      h[[ m.next_match_id, m.next_slot ]] = m
    end
    @next_match, @next_participants = next_unpredicted_match if @tournament.before?
  end

  # 未予想の試合のうち、トーナメント表の左上から順（回戦の若い順→上から順）で最初の1試合と、
  # その対戦する2人を返す。両方の選手が確定していない試合は飛ばす
  def next_unpredicted_match
    @all_matches.group_by(&:round).sort.flat_map(&:last).each do |match|
      next if @existing_predictions.key?(match.id)
      if match.round == 1
        participants = [ match.participant1, match.participant2 ]
      else
        # 2回戦以降は、前の試合で自分が予想した勝者が対戦する
        participants = [ 1, 2 ].map do |slot|
          feeder = @feeder_matches[[ match.id, slot ]]
          @existing_predictions[feeder&.id]&.predicted_participant
        end
      end
      return [ match, participants ] if participants.all?(&:present?)
    end
    nil
  end

  # 終了した試合に対する自分の予想結果を、新しい順に並べて返す
  def prediction_log
    current_user.predictions
                .where(match: @tournament.matches.finished)
                .includes(:predicted_participant, match: [ :participant1, :participant2, :winner ])
                .order(updated_at: :desc)
  end

  # 終了した試合に対する全ユーザーの予想を返す（的中率などの集計用）
  def all_finished_predictions
    Prediction.where(match: @tournament.matches.finished).includes(:match)
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

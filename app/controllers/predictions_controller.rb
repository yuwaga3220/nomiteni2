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

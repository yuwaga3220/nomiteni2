class PredictionsController < ApplicationController
  before_action :logged_in_user
  before_action :set_tournament

  def new
    @existing_predictions = current_user.predictions
                                        .where(match: @tournament.matches)
                                        .index_by(&:match_id)
  end

  def create
    Prediction.transaction do
      params[:predictions].each do |match_id, participant_id|
        next if participant_id.blank?
        match = @tournament.matches.find(match_id)
        prediction = current_user.predictions.find_or_initialize_by(match: match)
        prediction.update!(predicted_participant_id: participant_id)
      end
    end
    flash[:success] = "予想を確定しました"
    redirect_to tournament_path(@tournament)
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end
end

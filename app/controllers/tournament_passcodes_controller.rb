class TournamentPasscodesController < ApplicationController
  before_action :logged_in_user

  def create
    tournament = Tournament.find(params[:tournament_id])
    if tournament.passcode_digest.blank? || tournament.authenticate_passcode(params[:passcode])
      authorize_tournament!(tournament)
      redirect_to redirect_target(tournament)
    else
      flash[:danger] = "パスコードが正しくありません"
      redirect_to root_url
    end
  end

  private

  def redirect_target(tournament)
    params[:next] == "predictions" ? new_tournament_prediction_path(tournament) : tournament_path(tournament)
  end
end

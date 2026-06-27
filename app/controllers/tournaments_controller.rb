class TournamentsController < ApplicationController
  before_action :logged_in_user, only: [ :show, :create, :destroy, :update_status ]
  before_action :correct_user, only: [ :destroy, :update_status ]

  def show
    @tournament = Tournament.find(params[:id])
  end

  def create
    @tournament = current_user.tournaments.build(tournament_params)
    if @tournament.save
      flash[:success] = "大会を作成しました！"
      redirect_to root_url
    else
      @tournaments = Tournament.all.paginate(page: params[:page])
      render "static_pages/home", status: :unprocessable_entity
    end
  end

  def update_status
    if Tournament.statuses.key?(params[:status])
      Match.transaction do
        @tournament.update!(status: params[:status])
        if @tournament.before?
          @tournament.matches.update_all(winner_id: nil)
          @tournament.matches.where("round > 1")
                     .update_all(participant1_id: nil, participant2_id: nil)
        end
      end
    end
    redirect_to tournament_path(@tournament)
  end

  def destroy
    @tournament.destroy
    flash[:success] = "大会を削除しました"
    redirect_back_or_to(root_url, status: :see_other)
  end

  private

  def tournament_params
    params.require(:tournament).permit(:title, :description, :held_on, :venue)
  end

  def correct_user
    @tournament = current_user.tournaments.find_by(id: params[:id])
    redirect_to root_url, status: :see_other if @tournament.nil?
  end
end

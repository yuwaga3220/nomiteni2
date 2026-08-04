class TournamentsController < ApplicationController
  before_action :logged_in_user, only: [ :show, :new, :create, :destroy, :update_status ]
  before_action :correct_user, only: [ :destroy, :update_status ]

  def show
    @tournament = Tournament.find(params[:id])
  end

  def new
    @tournament = current_user.tournaments.build
  end

  def create
    @tournament = current_user.tournaments.build(tournament_params)
    if @tournament.save
      flash[:success] = "大会を作成しました！"
      redirect_to root_url
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update_status
    if params[:status].in?(%w[during after]) && @tournament.matches.empty?
      flash[:danger] = "トーナメントツリーが作成されていません！"
      redirect_to tournament_path(@tournament) and return
    end

    if params[:status] == "after" && !@tournament.matches.all?(&:finished?)
      flash[:danger] = "すべての試合が終了していません！"
      redirect_to tournament_path(@tournament) and return
    end

    if Tournament.statuses.key?(params[:status])
      Match.transaction do
        @tournament.update!(status: params[:status])
        if @tournament.before?
          @tournament.matches.update_all(winner_id: nil)
          @tournament.matches.where("round > 1")
                     .update_all(participant1_id: nil, participant2_id: nil)
        end
      end
      broadcast_tournament_status!(@tournament)
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
    params.require(:tournament).permit(:title, :description, :held_on, :venue, :image)
  end

  def correct_user
    @tournament = current_user.tournaments.find_by(id: params[:id])
    redirect_to root_url, status: :see_other if @tournament.nil?
  end
end

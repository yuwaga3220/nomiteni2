class TournamentsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: [:destroy]


  def create
    @tournament = current_user.tournaments.build(tournament_params)
    @tournament.image.attach(params[:tournament][:image])
    if @tournament.save
      flash[:success] = "大会を作成しました！"
      redirect_to root_url
    else
      @tournaments = Tournament.all.paginate(page: params[:page])
      render 'static_pages/home', status: :unprocessable_entity
    end
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

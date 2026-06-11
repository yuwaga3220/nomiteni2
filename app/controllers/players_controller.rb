class PlayersController < ApplicationController
  before_action :logged_in_user
  before_action :correct_tournament_user

  def create
    @player = @tournament.players.build(player_params)
    if @player.save
      flash[:success] = "プレイヤーを追加しました"
    else
      flash[:danger] = @player.errors.full_messages.join(", ")
    end
    redirect_to tournament_path(@tournament)
  end

  def destroy
    @player = @tournament.players.find(params[:id])
    @player.destroy
    flash[:success] = "プレイヤーを削除しました"
    redirect_to tournament_path(@tournament)
  end

  private

  def player_params
    params.require(:player).permit(:name, :position)
  end

  def correct_tournament_user
    @tournament = current_user.tournaments.find_by(id: params[:tournament_id])
    redirect_to root_url, status: :see_other if @tournament.nil?
  end
end

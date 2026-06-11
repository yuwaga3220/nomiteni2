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

  def update_positions
    positions = params[:positions].permit!.to_h
    blank_players = positions.select { |_, position| position.blank? }
                             .filter_map { |player_id, _| @tournament.players.find_by(id: player_id)&.name }
    if blank_players.any?
      flash[:danger] = "#{blank_players.join('、')} のポジションが入力されていません"
      redirect_to tournament_path(@tournament) and return
    end

    errors = []
    positions.each do |player_id, position|
      player = @tournament.players.find_by(id: player_id)
      next unless player
      errors << player.errors.full_messages unless player.update(position: position)
    end
    if errors.empty?
      flash[:success] = "ポジションを更新しました"
    else
      flash[:danger] = errors.flatten.join(", ")
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

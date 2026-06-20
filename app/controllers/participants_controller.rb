class ParticipantsController < ApplicationController
  before_action :logged_in_user
  before_action :correct_tournament_user

  def create
    @participant = @tournament.participants.build(participant_params)
    if @participant.save
      flash[:success] = "参加者を追加しました"
    else
      flash[:danger] = @participant.errors.full_messages.join(", ")
    end
    redirect_to tournament_path(@tournament)
  end

  def update_positions
    positions = params[:positions].permit!.to_h
    blank_participants = positions.select { |_, position| position.blank? }
                             .filter_map { |participant_id, _| @tournament.participants.find_by(id: participant_id)&.name }
    if blank_participants.any?
      flash[:danger] = "#{blank_participants.join('、')} のポジションが入力されていません"
      redirect_to tournament_path(@tournament) and return
    end

    errors = []
    positions.each do |participant_id, position|
      participant = @tournament.participants.find_by(id: participant_id)
      next unless participant
      errors << participant.errors.full_messages unless participant.update(position: position)
    end
    if errors.empty?
      flash[:success] = "ポジションを更新しました"
    else
      flash[:danger] = errors.flatten.join(", ")
    end
    redirect_to tournament_path(@tournament)
  end

  def destroy
    @participant = @tournament.participants.find(params[:id])
    @participant.destroy
    flash[:success] = "参加者を削除しました"
    redirect_to tournament_path(@tournament)
  end

  private

  def participant_params
    params.require(:participant).permit(:name, :position)
  end

  def correct_tournament_user
    @tournament = current_user.tournaments.find_by(id: params[:tournament_id])
    redirect_to root_url, status: :see_other if @tournament.nil?
  end
end

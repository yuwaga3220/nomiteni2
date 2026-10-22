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

  def update
    # 棄権のON/OFFは大会の状況にかかわらず受け付ける
    if params.dig(:participant, :withdrawn).present?
      update_withdrawn and return
    end
    unless @tournament.before?
      flash[:danger] = "開催前以外は参加者を編集できません"
      redirect_to tournament_path(@tournament) and return
    end
    @participant = @tournament.participants.find(params[:id])
    if @participant.update(participant_params)
      flash[:success] = "参加者名を更新しました"
    else
      flash[:danger] = @participant.errors.full_messages.join(", ")
    end
    redirect_to tournament_path(@tournament)
  end

  def destroy
    unless @tournament.before?
      flash[:danger] = "開催前以外は参加者を削除できません"
      redirect_to tournament_path(@tournament) and return
    end
    @participant = @tournament.participants.find(params[:id])
    @participant.destroy
    flash[:success] = "参加者を削除しました"
    redirect_to tournament_path(@tournament)
  end

  def reorder
    unless @tournament.before?
      head :unprocessable_entity and return
    end

    ids = Array(params[:participant_ids]).map(&:to_i)
    if ids.sort != @tournament.participants.pluck(:id).sort
      head :unprocessable_entity and return
    end

    Participant.transaction do
      ids.each_with_index do |id, index|
        @tournament.participants.where(id: id).update_all(position: index + 1)
      end
    end
    head :ok
  end

  private

  # 選手の棄権を設定・取り消しし、不戦勝の結果を対戦表に反映する
  def update_withdrawn
    @participant = @tournament.participants.find(params[:id])
    withdrawn = ActiveModel::Type::Boolean.new.cast(params[:participant][:withdrawn])
    if withdrawn ? @participant.withdraw : @participant.cancel_withdrawal
      flash[:success] = withdrawn ? "#{@participant.name}を棄権にしました" : "#{@participant.name}の棄権を取り消しました"
      broadcast_tournament_status!(@tournament)
    else
      flash[:danger] = @participant.errors.full_messages.join(", ")
    end
    redirect_to tournament_path(@tournament)
  end

  def participant_params
    params.require(:participant).permit(:name)
  end

  def correct_tournament_user
    @tournament = current_user.tournaments.find_by(id: params[:tournament_id])
    redirect_to root_url, status: :see_other if @tournament.nil?
  end
end

class MatchesController < ApplicationController
  before_action :logged_in_user
  before_action :correct_tournament_user

  def create
    positions = params[:positions].permit!.to_h
    count = @tournament.participants.count

    blank_names = positions.select { |_, position| position.blank? }
                            .filter_map { |participant_id, _| @tournament.participants.find_by(id: participant_id)&.name }
    if blank_names.any?
      flash[:danger] = "#{blank_names.join('、')} のポジションが入力されていません"
      redirect_to tournament_path(@tournament) and return
    end

    unless power_of_two?(count)
      flash[:danger] = "参加者数が2の冪乗（2, 4, 8...）でないため、トーナメントを作成できません"
      redirect_to tournament_path(@tournament) and return
    end

    position_values = positions.values.map(&:to_i)
    unless position_values.sort == (1..count).to_a
      flash[:danger] = "ポジションは1から#{count}までの値を重複なく入力してください"
      redirect_to tournament_path(@tournament) and return
    end

    ordered_participants = positions.sort_by { |_, position| position.to_i }
                                     .map { |participant_id, _| @tournament.participants.find(participant_id) }

    Match.transaction do
      @tournament.matches.destroy_all
      build_bracket(ordered_participants)
    end
    flash[:success] = "トーナメントツリーを作成しました"
    redirect_to tournament_path(@tournament)
  end

  private

  def power_of_two?(count)
    count >= 2 && (count & (count - 1)).zero?
  end

  def build_bracket(ordered_participants)
    count = ordered_participants.size
    rounds = Math.log2(count).to_i
    next_round_matches = nil
    rounds.downto(1) do |round|
      matches_count = count / (2**round)
      current_round_matches = Array.new(matches_count) do |i|
        attrs = { tournament: @tournament, round: round }
        attrs[:next_match] = next_round_matches[i / 2] if next_round_matches
        if round == 1
          attrs[:participant1] = ordered_participants[2 * i]
          attrs[:participant2] = ordered_participants[2 * i + 1]
        end
        Match.create!(attrs)
      end
      next_round_matches = current_round_matches
    end
  end

  def correct_tournament_user
    @tournament = current_user.tournaments.find_by(id: params[:tournament_id])
    redirect_to root_url, status: :see_other if @tournament.nil?
  end
end

class MatchesController < ApplicationController
  before_action :logged_in_user
  before_action :correct_tournament_user

  def create
    positions = params[:positions].permit!.to_h
    count = @tournament.participants.count

    blank_names = positions.select { |_, position| position.blank? }
                           .filter_map { |participant_id, _|
                           @tournament.participants.find_by(id: participant_id)&.name }
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
                                     .map { |participant_id, _|
                                     @tournament.participants.find(participant_id) }

    Match.transaction do
      @tournament.matches.update_all(next_match_id: nil)
      @tournament.matches.destroy_all
      build_bracket(ordered_participants)
    end
    flash[:success] = "トーナメントツリーを作成しました"
    redirect_to tournament_path(@tournament)
  end

  def set_winner
    if @tournament.before?
      flash[:danger] = "開催前は試合結果を入力できません"
      redirect_to tournament_path(@tournament) and return
    end
    match = @tournament.matches.find(params[:id])
    unless match.participant1 && match.participant2
      flash[:danger] = "両方の選手が決まっていない試合には結果を入力できません"
      redirect_to tournament_path(@tournament) and return
    end

    p1_games = params[:participant1_games].to_i
    p2_games = params[:participant2_games].to_i

    if p1_games == p2_games
      flash[:danger] = "同点の結果は入力できません"
      redirect_to tournament_path(@tournament) and return
    end

    winner, winner_games, loser_games =
      p1_games > p2_games ? [ match.participant1, p1_games, p2_games ] : [ match.participant2, p2_games, p1_games ]

    Match.transaction do
      match.update!(winner: winner, winner_games: winner_games, loser_games: loser_games, status: :finished)
      if match.next_match && match.next_slot
        next_match = match.next_match
        if match.next_slot == 1
          next_match.update!(participant1: winner)
        else
          next_match.update!(participant2: winner)
        end
      end
    end
    redirect_to tournament_path(@tournament)
  end

  def update_status
    if @tournament.before?
      flash[:danger] = "開催前は試合状況を更新できません"
      redirect_to tournament_path(@tournament) and return
    end
    match = @tournament.matches.find(params[:id])
    unless Match.statuses.key?(params[:status])
      flash[:danger] = "不正な試合状況です"
      redirect_to tournament_path(@tournament) and return
    end
    match.update!(court: params[:court], status: params[:status])
    redirect_to tournament_path(@tournament)
  end

  def destroy_all
    @tournament.matches.update_all(next_match_id: nil)
    @tournament.matches.destroy_all
    flash[:success] = "トーナメントツリーを削除しました"
    redirect_to tournament_path(@tournament)
  end

  private

  # 2の冪乗かチェックする
  def power_of_two?(count)
    count >= 2 && (count & (count - 1)).zero?
  end

  # 整列済みparticipantsを入力としてトーナメントツリーを構築する
  def build_bracket(ordered_participants)
    count = ordered_participants.size
    rounds = Math.log2(count).to_i
    next_round_matches = nil
    rounds.downto(1) do |round|
      matches_count = count / (2**round)
      current_round_matches = Array.new(matches_count) do |i|
        attrs = { tournament: @tournament, round: round }
        if next_round_matches
          attrs[:next_match] = next_round_matches[i / 2]
          attrs[:next_slot] = (i % 2) + 1
        end
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

class MatchesController < ApplicationController
  before_action :logged_in_user
  before_action :correct_tournament_user

  def create
    count = @tournament.participants.count

    unless power_of_two?(count)
      flash[:danger] = "選手数が条件を満たしていません。"
      redirect_to tournament_path(@tournament) and return
    end

    # 表示順（ドラッグ&ドロップで並び替えられたposition）をそのままポジションとして割り当てる
    ordered_participants = @tournament.participants.order(:position, :id).to_a

    Match.transaction do
      @tournament.matches.update_all(next_match_id: nil)
      @tournament.matches.destroy_all
      build_bracket(ordered_participants)
    end
    broadcast_tournament_status!(@tournament)
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
    if match.result_locked?
      flash[:danger] = "次の試合が開始しているため、この試合の結果は変更できません"
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
      match.predictions.each do |prediction|
        points = prediction.predicted_participant_id == winner.id ? 10 : 0
        prediction.update!(points: points)
      end
    end
    broadcast_tournament_status!(@tournament)
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
    if match.result_locked?
      flash[:danger] = "次の試合が開始しているため、この試合の状況は変更できません"
      redirect_to tournament_path(@tournament) and return
    end
    attrs = { court: params[:court], status: params[:status] }
    # 予備に戻したら、それまでの結果（勝者・ゲーム数）はリセットする
    attrs.merge!(winner: nil, winner_games: nil, loser_games: nil) if params[:status] == "pending"
    match.update!(attrs)
    broadcast_tournament_status!(@tournament)
    redirect_to tournament_path(@tournament)
  end

  def destroy_all
    @tournament.matches.update_all(next_match_id: nil)
    @tournament.matches.destroy_all
    broadcast_tournament_status!(@tournament)
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

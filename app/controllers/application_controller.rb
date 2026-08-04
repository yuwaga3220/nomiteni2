class ApplicationController < ActionController::Base
  include SessionsHelper

  private

  # 大会状況（ステータス・試合結果・コート状況）の変化を、大会詳細画面を開いている
  # 全ユーザーにリアルタイムで反映する。オーナー用・公開用のストリームに分けて
  # それぞれ異なる権限（owner_view）でレンダリングしたHTMLを配信する
  def broadcast_tournament_status!(tournament)
    tournament.reload
    Turbo::StreamsChannel.broadcast_replace_to(
      "tournament_#{tournament.id}_owner",
      target: "tournament-status-section",
      partial: "tournaments/status_section",
      locals: { tournament: tournament, owner_view: true }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "tournament_#{tournament.id}_public",
      target: "tournament-status-section",
      partial: "tournaments/status_section",
      locals: { tournament: tournament, owner_view: false }
    )
  end

  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "ログインしてください。"
      redirect_to login_url, status: :see_other
    end
  end
end

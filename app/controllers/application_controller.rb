class ApplicationController < ActionController::Base
  include SessionsHelper

  before_action :open_in_external_browser

  private

  # LINEのアプリ内ブラウザで開かれたら、既定のブラウザで開き直す
  # （openExternalBrowser=1 を付けたURLは、LINEが外部ブラウザで開く）
  def open_in_external_browser
    return unless request.get? && request.format.html?
    return unless request.user_agent.to_s.match?(/\bLine\//)
    return if params[:openExternalBrowser].present?

    redirect_to url_for(request.query_parameters.merge(openExternalBrowser: 1)), allow_other_host: false
  end

  # 大会状況（ステータス・試合結果・コート状況）の変化を、大会詳細画面を開いている
  # 全ユーザーにリアルタイムで反映する。オーナー用・公開用のストリームに分けて
  # それぞれ異なる権限（owner_view）でレンダリングしたHTMLを配信する
  def broadcast_tournament_status!(tournament)
    tournament.reload
    Turbo::StreamsChannel.broadcast_replace_to(
      "tournament_#{tournament.id}_owner",
      target: "tournament-status-section",
      partial: "tournaments/status_section",
      locals: { tournament: tournament, owner_view: true, preserve_scroll: true }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "tournament_#{tournament.id}_public",
      target: "tournament-status-section",
      partial: "tournaments/status_section",
      locals: { tournament: tournament, owner_view: false, preserve_scroll: true }
    )
  end

  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "ログインしてください。"
      redirect_to login_url, status: :see_other
    end
  end

  # 非公開（選手が未登録）の大会にオーナー以外がアクセスしようとした場合や、
  # パスコードが必要な大会に、認可されていない状態でアクセスしようとした場合はrootへ戻す。
  # 戻り値がtrueならブロックした（呼び出し元は続けて `return if ...` で処理を止める）
  def block_unless_tournament_accessible(tournament)
    if !current_user?(tournament.user) && !tournament.published?
      flash[:danger] = "この大会はまだ公開されていません"
      redirect_to root_url
      return true
    end
    return false unless tournament_passcode_required?(tournament)
    flash[:danger] = "パスコードが必要です。大会一覧からアクセスしてください"
    redirect_to root_url
    true
  end
end

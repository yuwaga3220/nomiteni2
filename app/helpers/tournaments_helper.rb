module TournamentsHelper
  # 大会の予定をGoogleカレンダーに登録するためのURLを生成する
  def google_calendar_url(tournament)
    dates = "#{tournament.held_on.strftime('%Y%m%d')}/#{(tournament.held_on + 1.day).strftime('%Y%m%d')}"
    params = {
      action: "TEMPLATE",
      text: tournament.title,
      dates: dates,
      location: tournament.venue.presence
    }.compact
    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end
end

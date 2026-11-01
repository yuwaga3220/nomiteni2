class StaticPagesController < ApplicationController
  def home
    # 大会一覧はログイン前でも表示する
    status_order = Arel.sql("CASE status WHEN 1 THEN 0 WHEN 0 THEN 1 WHEN 2 THEN 2 END")
    @tournaments = Tournament.with_attached_image.reorder(status_order, created_at: :desc).paginate(page: params[:page])
  end

  def help
  end

  def contact
  end

  def privacy
  end
end

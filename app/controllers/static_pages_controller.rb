class StaticPagesController < ApplicationController
  def home
    if logged_in?
      @tournament = current_user.tournaments.build
      @tournaments = Tournament.all.paginate(page: params[:page])
    end
  end

  def help
  end

  def about
  end

  def contact
  end
end

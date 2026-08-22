class AdminController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user

  def index
  end

  private

  def admin_user
    redirect_to(root_url, status: :see_other) unless current_user.admin?
  end
end

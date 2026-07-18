class SessionsController < ApplicationController
  def new
  end

  def create
    @user = User.find_by(email: params[:session][:email].downcase)
    if @user&.authenticate(params[:session][:password])
      if @user.activated?
        forwarding_url = session[:forwarding_url]
        reset_session
        params[:session][:remember_me] == "1" ? remember(@user) : forget(@user)
        log_in @user
        redirect_to forwarding_url || root_url
      else
        message = "アカウントがまだ有効化されていません。"
        message += "メールに記載された有効化リンクをご確認ください"
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = "メールアドレスまたはパスワードが正しくありません"
      render "new", status: :unprocessable_entity
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url, status: :see_other
  end
end

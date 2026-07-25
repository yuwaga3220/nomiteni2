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

  def omniauth
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)
    if user.persisted?
      forwarding_url = session[:forwarding_url]
      reset_session
      log_in user
      redirect_to forwarding_url || root_url
    else
      flash[:danger] = "Googleアカウントでのログインに失敗しました"
      redirect_to login_url
    end
  end

  def omniauth_failure
    flash[:danger] = "Googleアカウントでのログインに失敗しました"
    redirect_to login_url
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url, status: :see_other
  end
end

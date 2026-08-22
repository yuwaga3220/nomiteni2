Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  # Kamal/kamal-proxyがコンテナの生存確認に使うヘルスチェック用エンドポイント
  get "up" => "rails/health#show", as: :rails_health_check

  root "static_pages#home"
  get  "/help",     to: "static_pages#help"
  get  "/contact",  to: "static_pages#contact"
  get  "/privacy",  to: "static_pages#privacy"
  get  "/signup",   to: "users#new"
  get  "/login",    to: "sessions#new"
  post "/login",    to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  get "/auth/:provider/callback", to: "sessions#omniauth"
  get "/auth/failure",            to: "sessions#omniauth_failure"
  resources :users
  get "/admin", to: "admin#index"
  resources :account_activations, only: [ :edit ]
  resources :password_resets, only: [ :new, :create, :edit, :update ]
  resources :tournaments, only: [ :new, :create, :destroy, :show ] do
    member do
      patch :update_status
    end
    resource :prediction, only: [ :new, :create ]
    resource :passcode, only: [ :create ], controller: "tournament_passcodes"
    resources :participants, only: [ :create, :update, :destroy ] do
      collection do
        patch :reorder
      end
    end
    resources :matches, only: [ :create ] do
      collection do
        delete :destroy_all
      end
      member do
        patch :set_winner
        patch :update_status
      end
    end
  end
end

Rails.application.routes.draw do
  root "static_pages#home"
  get  "/help",     to: "static_pages#help"
  get  "/about",    to: "static_pages#about"
  get  "/contact",  to: "static_pages#contact"
  get  "/signup",   to: "users#new"
  get  "/login",    to: "sessions#new"
  post "/login",    to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  resources :users
  resources :account_activations, only: [ :edit ]
  resources :password_resets, only: [ :new, :create, :edit, :update ]
  resources :tournaments, only: [ :create, :destroy, :show ] do
    resources :participants, only: [ :create, :destroy ]
    resources :matches, only: [ :create ] do
      collection do
        delete :destroy_all
      end
      member do
        patch :set_winner
      end
    end
  end
end

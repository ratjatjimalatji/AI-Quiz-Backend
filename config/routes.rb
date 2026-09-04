Rails.application.routes.draw do
  get "rounds/index"
  get "rounds/create"
  get "rounds/show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  resources :players, only: [ :index, :show ]
  resources :games, only: [ :index ] do
    post :create_player, on: :collection
    get :get_players, on: :collection
end
  resources :questions, only: [ :index, :create, :show, :update ]
  resources :rounds, only: [ :index, :create, :show ]
  resources :hosts, only: [ :index, :create ] do
    post :create_game, on: :member
  end
end

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => "/cable"

  # Defines the root path route ("/")
  # root "posts#index"
  resources :players, only: [ :index, :show ] do
    post :rejoin, on: :collection
  end

  resources :games, only: [ :index ] do
    post :create_player, on: :collection
    post :advance_step, on: :member
    get :get_players, to: "games#get_players"
  end

  resources :questions, only: [ :index, :create, :show, :update ]
  resources :rounds, only: [ :index, :create, :show ]

  resources :hosts, only: [ :index, :create ] do
    post :create_game, on: :member
    post :rejoin, on: :collection
  end
  resources :submissions, only: [ :create ]

  post "power_ups/use", to: "power_ups#use"
end

resources :polls, only: [:show, :index] do
  member do
    get :stats
    get :results
    post :answer
  end
end

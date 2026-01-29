Dummy::Application.routes.draw do
  root to: 'application#index'
  resources :users
end

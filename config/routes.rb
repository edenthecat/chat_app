Rails.application.routes.draw do
  resources :conversations do
    resources :messages, only: [:index, :new, :create, :destroy]
  end
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

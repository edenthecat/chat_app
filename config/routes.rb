Rails.application.routes.draw do
  resources :conversations do
    resources :messages, only: [:index, :new, :create, :destroy]
  end

  get '/conversations/:id/refresh_messages', to: 'conversations#refresh_messages', as: 'refresh_messages'
  devise_for :users
  root to: 'conversations#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

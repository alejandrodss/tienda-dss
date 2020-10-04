Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'payments#new'
  resources :payments, only: [:index, :show, :new, :create, :update]
end

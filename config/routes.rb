Rails.application.routes.draw do
  get '/pages/:page', to: 'pages#show'

  resources :application_forms do
    get 'success/:application_form_id', to: 'application_forms#success', as: :success
  end
  resources :allocation_request_forms do
    get 'success', to: 'allocation_request_forms#success'
  end

  resources :sessions, only: %i[create destroy]

  resources :sign_in_tokens, only: %i[new create]
  get '/token/:token/:identifier/validate', to: 'sign_in_tokens#validate', as: :validate_sign_in_token
  get '/token/manual', to: 'sign_in_tokens#manual', as: :validate_manually_entered_sign_in_token

  get '/sign_in', to: 'sign_in_tokens#new', as: :sign_in

  get '/404', to: 'errors#not_found', via: :all
  get '/422', to: 'errors#unprocessable_entity', via: :all
  get '/500', to: 'errors#internal_server_error', via: :all

  get '/', to: redirect('pages/guidance')
end

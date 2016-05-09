require 'sidekiq/web'

Rails.application.routes.draw do
  post 'webhooks' => 'webhooks#create'

  if AuthProvider.active.providable_type == DatabaseProvider.name
    # with local authentification we do not use omniAuth so we must differentiate the config
    devise_for :users, controllers: {registrations: 'registrations', sessions: 'sessions',
                                     confirmations: 'confirmations', passwords: 'passwords'}
  else
    devise_for :users, controllers: {registrations: 'registrations', sessions: 'sessions',
                                     confirmations: 'confirmations', passwords: 'passwords',
                                     :omniauth_callbacks => 'users/omniauth_callbacks'}
  end


  ## The priority is based upon order of creation: first created -> highest priority.
  ## See how all your routes lay out with "rake routes".

  ## You can have the root of your site routed with "root"
  root 'application#index'

  namespace :api, as: nil, defaults: { format: :json } do
    resources :projects, only: [:index, :last_published, :show, :create, :update, :destroy] do
      collection do
        get :last_published
        get :search
      end
    end
    resources :openlab_projects, only: :index
    resources :machines
    resources :components
    resources :themes
    resources :licences
    resources :admins, only: [:index, :create, :destroy]
    resources :settings, only: [:show, :update, :index], param: :name
    resources :users, only: [:index, :create]
    resources :members, only: [:index, :show, :create, :update, :destroy] do
      get '/export_subscriptions', action: 'export_subscriptions', on: :collection
      get '/export_reservations', action: 'export_reservations', on: :collection
      get '/export_members', action: 'export_members', on: :collection
      put ':id/merge', action: 'merge', on: :collection
    end
    resources :reservations, only: [:show, :create, :index, :update]
    resources :notifications, only: [:index, :show, :update] do
      match :update_all, path: '/', via: [:put, :patch], on: :collection
    end

    # for homepage
    get '/last_subscribed/:last' => "members#last_subscribed"
    get '/feeds/twitter_timelines' => "feeds#twitter_timelines"

    get 'pricing' => "pricing#index"
    put 'pricing' => "pricing#update"

    resources :prices, only: [:index, :update] do
      post 'compute', on: :collection
    end

    resources :trainings_pricings, only: [:index, :update]

    resources :availabilities do
      get 'machines/:machine_id', action: 'machine', on: :collection
      get 'trainings', on: :collection
      get 'reservations', on: :member
    end

    resources :groups, only: [:index, :create, :update, :destroy]
    resources :subscriptions, only: [:show, :create, :update]
    resources :plans, only: [:index, :create, :update, :destroy, :show]
    resources :slots, only: [:update] do
      put 'cancel', on: :member
    end

    resources :events do
      get 'upcoming/:limit', action: 'upcoming', on: :collection
    end

    resources :invoices, only: [:index, :show, :create] do
      get 'download', action: 'download', on: :member
    end

    # for admin
    resources :trainings
    resources :credits
    resources :categories, only: [:index]
    resources :statistics, only: [:index]
    resources :custom_assets, only: [:show, :create, :update]
    resources :tags
    resources :stylesheets, only: [:show]
    resources :auth_providers do
      get 'mapping_fields', on: :collection
      get 'active', action: 'active', on: :collection
    end
    resources :abuses, only: [:create]
    resources :open_api_clients, only: [:index, :create, :update, :destroy] do
      patch :reset_token, on: :member
    end

    # i18n
    get 'translations/:locale/:state' => 'translations#show', :constraints => { :state => /[^\/]+/ } # allow dots in URL for 'state'
  end

  # open_api

  namespace :open_api do
    namespace :v1 do
      scope only: :index do
        resources :users
        resources :trainings
        resources :user_trainings
        resources :reservations
        resources :machines
        resources :bookable_machines
        resources :invoices do
          get :download, on: :member
        end
        resources :events
        resources :availabilities
      end
    end
  end

  %w(account event machine project subscription training user).each do |path|
    post "/stats/#{path}/_search", to: "api/statistics##{path}"
  end

  match '/project_collaborator/:valid_token', to: 'api/projects#collaborator_valid', via: :get

  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

  apipie
end

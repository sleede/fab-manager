# frozen_string_literal: true

require 'sidekiq_unique_jobs/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  if Rails.configuration.auth_provider.providable_type == 'DatabaseProvider'
    # with local authentication we do not use omniAuth so we must differentiate the config
    devise_for :users, controllers: {
      registrations: 'registrations', sessions: 'sessions', confirmations: 'confirmations', passwords: 'passwords'
    }
  else
    devise_for :users, controllers: {
      registrations: 'registrations', sessions: 'sessions', confirmations: 'confirmations', passwords: 'passwords',
      omniauth_callbacks: 'users/omniauth_callbacks'
    }
    get '/sso-redirect', to: 'application#sso_redirect', as: :sso_redirect
  end

  devise_scope :user do
    get '/sessions/sign_out', to: 'devise/sessions#destroy'
    post '/password/verify', to: 'passwords#verify'
  end

  ## The priority is based upon order of creation: first created -> highest priority.
  ## See how all your routes lay out with "rake routes".

  constraints user_agent: %r{facebookexternalhit/[0-9]|Twitterbot|Pinterest|Google.*snippet} do
    root to: 'social_bot#share', as: :bot_root
  end

  ## You can have the root of your site routed with "root"
  root 'application#index'

  namespace :api, as: nil, defaults: { format: :json } do
    resources :projects, only: %i[index show create update destroy] do
      collection do
        get :last_published
        get :search
      end
      get :markdown, on: :member
    end
    resources :openlab_projects, only: :index
    resources :machines
    resources :machine_categories
    resources :components
    resources :themes
    resources :licences
    resources :statuses
    resources :project_categories
    resources :admins, only: %i[index create destroy]
    resources :settings, only: %i[show update index], param: :name do
      patch '/bulk_update', action: 'bulk_update', on: :collection
      put '/reset/:name', action: 'reset', on: :collection
      get '/is_present/:name', action: 'test_present', on: :collection
    end
    resources :users, only: %i[index create destroy]
    resources :members, only: %i[index show create update destroy] do
      get '/export_subscriptions', action: 'export_subscriptions', on: :collection
      get '/export_reservations', action: 'export_reservations', on: :collection
      get '/export_members', action: 'export_members', on: :collection
      get 'current', action: 'current', on: :collection
      put ':id/merge', action: 'merge', on: :collection
      post 'list', action: 'list', on: :collection
      get 'search/:query', action: 'search', on: :collection
      get 'mapping', action: 'mapping', on: :collection
      patch ':id/complete_tour', action: 'complete_tour', on: :collection
      patch ':id/update_role', action: 'update_role', on: :collection
      patch ':id/validate', action: 'validate', on: :collection
    end
    resources :reservations, only: %i[show index update] do
      post :confirm_payment, on: :collection
    end
    resources :notifications, only: %i[index show update] do
      match :update_all, path: '/', via: %i[put patch], on: :collection
      get 'polling', action: 'polling', on: :collection
      get 'last_unread', action: 'last_unread', on: :collection
    end
    resources :notification_types, only: %i[index]
    resources :notification_preferences, only: %i[index update], param: :notification_type do
      patch '/bulk_update', action: 'bulk_update', on: :collection
    end
    resources :wallet, only: [] do
      get '/by_user/:user_id', action: 'by_user', on: :collection
      get :transactions, on: :member
      put :credit, on: :member
    end

    # for homepage
    get '/last_subscribed/:last' => 'members#last_subscribed'

    get 'pricing' => 'pricing#index'
    put 'pricing' => 'pricing#update'

    resources :prices, only: %i[create index update destroy] do
      post 'compute', on: :collection
    end
    resources :prepaid_packs
    resources :coupons do
      post 'validate', action: 'validate', on: :collection
      post 'send', action: 'send_to', on: :collection
    end
    resources :user_packs, only: %i[index]

    resources :trainings_pricings, only: %i[index update]

    resources :availabilities do
      get 'machines/:machine_id', action: 'machine', on: :collection
      get 'trainings/:training_id', action: 'trainings', on: :collection
      get 'spaces/:space_id', action: 'spaces', on: :collection
      get 'reservations', on: :member
      get 'public', on: :collection
      get '/export_index', action: 'export_availabilities', on: :collection
      put ':id/lock', action: 'lock', on: :collection
    end

    resources :groups, only: %i[index create update destroy]
    resources :subscriptions, only: %i[show] do
      get 'payment_details', action: 'payment_details', on: :member
      patch 'cancel', on: :member
    end
    resources :plan_categories
    resources :plans do
      get 'durations', on: :collection
    end
    resources :slots_reservations, only: [:update] do
      put 'cancel', on: :member
      put 'validate', on: :member
      put 'invalidate', on: :member
    end

    resources :events do
      get 'upcoming/:limit', action: 'upcoming', on: :collection
    end

    resources :invoices, only: %i[index show create] do
      get 'download', action: 'download', on: :member
      post 'list', action: 'list', on: :collection
      get 'first', action: 'first', on: :collection
    end

    resources :payment_schedules, only: %i[index show update] do
      post 'list', action: 'list', on: :collection
      put 'cancel', on: :member
      get 'download', on: :member
      get 'items/:id', action: 'show_item', on: :collection
      post 'items/:id/cash_check', action: 'cash_check', on: :collection
      post 'items/:id/confirm_transfer', action: 'confirm_transfer', on: :collection
      post 'items/:id/refresh_item', action: 'refresh_item', on: :collection
      post 'items/:id/pay_item', action: 'pay_item', on: :collection
    end

    resources :i_calendar, only: %i[index create destroy] do
      get 'events', on: :member
      post 'sync', on: :member
    end

    resources :supporting_document_types
    resources :supporting_document_files, only: %i[index show create update] do
      get 'download', on: :member
    end
    resources :supporting_document_refusals, only: %i[index show create]

    resources :profile_custom_fields

    resources :product_categories do
      patch 'position', on: :member
    end

    resources :products do
      put 'clone', on: :member
      get 'stock_movements', on: :member
    end
    resources :cart, only: %i[create] do
      put 'add_item', on: :collection
      put 'remove_item', on: :collection
      put 'set_quantity', on: :collection
      put 'set_offer', on: :collection
      put 'refresh_item', on: :collection
      post 'validate', on: :collection
      post 'create_item', on: :collection
      put 'set_customer', on: :collection
    end
    resources :checkout, only: %i[] do
      post 'payment', on: :collection
      post 'confirm_payment', on: :collection
    end
    resources :orders, except: %i[create] do
      get 'withdrawal_instructions', on: :member
    end

    resources :children do
      patch ':id/validate', action: 'validate', on: :collection
    end

    # for admin
    resources :trainings do
      get :availabilities, on: :member
    end
    resources :credits do
      get 'user/:id/:resource', action: :user_resource, on: :collection
    end
    resources :categories
    resources :event_themes
    resources :age_ranges
    resources :statistics, only: [:index]
    resources :custom_assets, only: %i[show create update]
    resources :tags
    resources :stylesheets, only: [:show]
    resources :auth_providers do
      get 'mapping_fields', on: :collection
      get 'active', action: 'active', on: :collection
      post 'send_code', action: 'send_code', on: :collection
      get 'strategy_name', action: 'strategy_name', on: :collection
    end
    resources :abuses, only: %i[index create destroy]
    resources :open_api_clients, only: %i[index create update destroy] do
      patch :reset_token, on: :member
    end
    resources :price_categories
    resources :spaces
    resources :accounting_periods do
      get 'last_closing_end', on: :collection
      get 'archive', action: 'download_archive', on: :member
    end
    # export accounting data to csv or equivalent
    post 'accounting/export' => 'accounting_exports#export'
    resources :reservation_contexts do
      get :applicable_on_values, on: :collection
    end

    # i18n
    # regex allows using dots in URL for 'state'
    get 'translations/:locale/:state' => 'translations#show', :constraints => { state: %r{[^/]+} }

    # XLSX exports
    get 'exports/:id/download' => 'exports#download'
    post 'exports/status' => 'exports#status'

    # Members CSV import
    resources :imports, only: [:show] do
      post 'members', action: 'members', on: :collection
    end

    # Fab-manager's version
    post 'version' => 'version#show'

    # card payments handling
    ## Stripe gateway
    post 'stripe/confirm_payment' => 'stripe/confirm_payment'
    get 'stripe/online_payment_status' => 'stripe/online_payment_status'
    get 'stripe/setup_intent/:user_id' => 'stripe#setup_intent'
    post 'stripe/setup_subscription' => 'stripe/setup_subscription'
    post 'stripe/confirm_subscription' => 'stripe#confirm_subscription'
    post 'stripe/update_card' => 'stripe#update_card'

    ## PayZen gateway
    post 'payzen/sdk_test' => 'payzen#sdk_test'
    post 'payzen/create_payment' => 'payzen#create_payment'
    post 'payzen/confirm_payment' => 'payzen#confirm_payment'
    post 'payzen/confirm_payment_schedule' => 'payzen#confirm_payment_schedule'
    post 'payzen/check_hash' => 'payzen#check_hash'
    post 'payzen/create_token' => 'payzen#create_token'
    post 'payzen/update_token' => 'payzen#update_token'
    post 'payzen/check_cart' => 'payzen#check_cart'

    # local payments handling
    post 'local_payment/confirm_payment' => 'local_payment#confirm_payment'

    # FabAnalytics
    get 'analytics/data' => 'analytics#data'

    # test MIME type
    post 'files/mime_type' => 'files#mime'
  end

  # rss

  namespace :rss, as: nil, defaults: { format: :xml } do
    resources :projects, only: [:index], as: 'rss_projects'
    resources :events, only: [:index], as: 'rss_events'
  end

  # open_api

  namespace :open_api do
    namespace :v1 do
      scope only: :index do
        resources :plans, only: %i[index show]
        resources :plan_categories
        resources :prices
        resources :users
        resources :trainings
        resources :user_trainings
        resources :reservations
        resources :machines, only: %i[index create update show destroy]
        resources :spaces, only: %i[index show]
        resources :bookable_machines
        resources :invoices do
          get :download, on: :member
        end
        resources :events
        resources :availabilities
        resources :accounting
        resources :subscriptions
      end
    end
  end

  %w[account event machine project subscription training user space order].each do |path|
    post "/stats/#{path}/_search", to: "api/statistics##{path}"
    post "/stats/#{path}/export", to: "api/statistics#export_#{path}"
  end
  post '/stats/global/export', to: 'api/statistics#export_global'
  post '_search/scroll', to: 'api/statistics#scroll'

  get '/project_collaborator/:valid_token', to: 'api/projects#collaborator_valid'

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

  get 'health' => 'health#status'

  apipie
end

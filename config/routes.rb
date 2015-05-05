require 'sidekiq/web'

Rails.application.routes.draw do
  post 'webhooks' => 'webhooks#create'

  devise_for :users, controllers: {registrations: "registrations", sessions: 'sessions',
                                   confirmations: 'confirmations', passwords: 'passwords'}

  ## The priority is based upon order of creation: first created -> highest priority.
  ## See how all your routes lay out with "rake routes".

  ## You can have the root of your site routed with "root"
  root 'application#index'

  namespace :api, as: nil, defaults: { format: :json } do
    resources :projects, only: [:index, :last_published, :show, :create, :update, :destroy] do
      collection do
        get :last_published
      end
    end
    resources :machines
    resources :components
    resources :themes
    resources :licences
    resources :members, only: [:index, :show, :create, :update] do
      get '/export_members', action: 'export_members', on: :collection
    end
    resources :notifications, only: [:index, :show, :update] do
      match :update_all, path: '/', via: [:put, :patch], on: :collection
    end

    # for homepage
    get '/last_subscribed/:last' => "members#last_subscribed"
    get '/feeds/twitter_timelines' => "feeds#twitter_timelines"

    get 'groups' => "groups#index"

    resources :events do
      get 'upcoming/:limit', action: 'upcoming', on: :collection
    end

    # for admin
    resources :categories, only: [:index]
  end

  match '/project_collaborator/:valid_token', to: 'api/projects#collaborator_valid', via: :get

  authenticate :user, lambda { |u| u.has_role? :admin } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

end

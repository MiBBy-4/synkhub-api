# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "signup", to: "registrations#create"
      post "login",  to: "sessions#create"
      get  "me",     to: "users#me"

      # GitHub OAuth
      namespace :github do
        get    "auth",       to: "/api/v1/github#auth"
        post   "callback",   to: "/api/v1/github#callback"
        delete "disconnect", to: "/api/v1/github#disconnect"

        resources :repositories, only: [:index]
        resources :subscriptions, only: [:index, :create, :destroy]
        resources :notifications, only: [:index] do
          member do
            patch :read
          end
          collection do
            patch :read_all
          end
        end
      end

      # Webhooks
      post "webhooks/github", to: "webhooks#github"
    end
  end
end

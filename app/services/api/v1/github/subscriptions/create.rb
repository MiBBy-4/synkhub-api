# frozen_string_literal: true

module Api
  module V1
    module Github
      module Subscriptions
        class Create < BaseService
          attr_reader :user, :github_repo_id, :repo_full_name

          GITHUB_API_URL = "https://api.github.com"

          def initialize(user:, github_repo_id:, repo_full_name:)
            @user = user
            @github_repo_id = github_repo_id
            @repo_full_name = repo_full_name
          end

          REQUIRED_SCOPE = Api::V1::Github::GenerateAuthUrl::ADMIN_REPO_HOOK_SCOPE

          def call
            return fail!("GitHub account not connected") unless user.github_connected?
            return fail!("Missing required GitHub scope: admin:repo_hook. Please reconnect your GitHub account.") unless required_scope?

            if user.github_repo_subscriptions.where(github_repo_id: github_repo_id).exists?
              return fail!("Already subscribed")
            end

            webhook_data = create_webhook
            return fail!("Failed to create webhook on GitHub") unless webhook_data && webhook_data["id"]

            subscription = user.github_repo_subscriptions.create!(
              github_repo_id: github_repo_id,
              repo_full_name: repo_full_name,
              webhook_github_id: webhook_data["id"]
            )

            success(subscription)
          end

          private

          attr_writer :user, :github_repo_id, :repo_full_name

          def required_scope?
            return false if user.github_token_scope.blank?

            user.github_token_scope.split(/[\s,]+/).include?(REQUIRED_SCOPE)
          end

          def create_webhook
            response = api_connection.post("/repos/#{repo_full_name}/hooks", {
                                             name: "web",
                                             active: true,
                                             events: GithubWebhookEvent::SUPPORTED_EVENTS,
                                             config: {
                                               url: ENV.fetch("GITHUB_WEBHOOK_URL"),
                                               content_type: "json",
                                               secret: ENV.fetch("GITHUB_WEBHOOK_SECRET"),
                                             },
                                           })

            response.body
          end

          def api_connection
            Faraday.new(url: GITHUB_API_URL) do |f|
              f.request :json
              f.response :json
              f.headers["Authorization"] = "Bearer #{user.github_access_token}"
              f.headers["User-Agent"] = "SynkHub"
            end
          end
        end
      end
    end
  end
end

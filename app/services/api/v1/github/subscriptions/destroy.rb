# frozen_string_literal: true

module Api
  module V1
    module Github
      module Subscriptions
        class Destroy < BaseService
          attr_reader :user, :subscription_id

          GITHUB_API_URL = "https://api.github.com"

          def initialize(user:, subscription_id:)
            @user = user
            @subscription_id = subscription_id
          end

          def call
            subscription = user.github_repo_subscriptions.find_by(id: subscription_id)
            return fail!("Subscription not found") unless subscription

            delete_webhook(subscription)
            subscription.destroy!

            success(subscription)
          end

          private

          attr_writer :user, :subscription_id

          def delete_webhook(subscription)
            return unless subscription.webhook_github_id

            api_connection.delete(
              "/repos/#{subscription.repo_full_name}/hooks/#{subscription.webhook_github_id}"
            )
          rescue Faraday::Error
            # Gracefully handle if webhook already deleted
            nil
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

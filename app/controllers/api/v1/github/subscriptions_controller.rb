# frozen_string_literal: true

module Api
  module V1
    module Github
      class SubscriptionsController < AuthenticatedController
        def index
          subscriptions = github_repo_subscriptions_scope

          respond_with_serialized_resources_collection(subscriptions, serializer: GithubRepoSubscriptionSerializer)
        end

        def create
          result = Api::V1::Github::Subscriptions::Create.call(**subscription_params)

          respond_with_service_result(result, serializer: GithubRepoSubscriptionSerializer)
        end

        def destroy
          result = Api::V1::Github::Subscriptions::Destroy.call(
            user: current_user,
            subscription_id: params[:id]
          )

          respond_with_no_content_service_result(result)
        end

        private

        def github_repo_subscriptions_scope
          current_user.github_repo_subscriptions
        end

        def subscription_params
          params.permit(:github_repo_id, :repo_full_name).to_h.symbolize_keys.merge(user: current_user)
        end
      end
    end
  end
end

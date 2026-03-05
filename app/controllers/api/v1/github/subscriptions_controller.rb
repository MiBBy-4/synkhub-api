# frozen_string_literal: true

module Api
  module V1
    module Github
      class SubscriptionsController < AuthenticatedController
        include Pagy::Backend

        def index
          pagy, subs = pagy(github_repo_subscriptions_scope.order(created_at: :desc), **pagy_options)

          respond_with_query_results(pagy, subs, serializer: GithubRepoSubscriptionSerializer)
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

        def page_params
          params.permit(:page, :limit)
        end

        def pagy_options
          options = {}
          options[:page] = page_params[:page] if page_params[:page].present?
          options[:limit] = page_params[:limit] if page_params[:limit].present?
          options
        end
      end
    end
  end
end

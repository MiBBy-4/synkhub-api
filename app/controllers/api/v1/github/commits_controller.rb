# frozen_string_literal: true

module Api
  module V1
    module Github
      class CommitsController < AuthenticatedController
        def index
          result = Api::V1::Github::ListCommits.call(user: current_user, **commit_params)

          if result.success?
            pr = result.value
            meta = {
              pagination: {
                current_page: pr.page,
                per_page: pr.limit,
                total_count: pr.total,
                total_pages: (pr.total.to_f / pr.limit).ceil,
              },
            }
            respond_with_serialized_resources_collection(pr.items, serializer: GithubCommitSerializer, meta: meta)
          else
            respond_with_unprocessable_entity(result.error)
          end
        end

        private

        def page_params
          params.permit(:page, :limit)
        end

        def commit_params
          options = {}
          options[:page] = page_params[:page].to_i if page_params[:page].present?
          options[:limit] = page_params[:limit].to_i if page_params[:limit].present?
          options
        end
      end
    end
  end
end

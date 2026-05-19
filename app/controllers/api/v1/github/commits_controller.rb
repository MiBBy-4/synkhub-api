# frozen_string_literal: true

module Api
  module V1
    module Github
      class CommitsController < AuthenticatedController
        def index
          result = Api::V1::Github::ListCommits.call(user: current_user)

          respond_with_service_result_collection(result, serializer: GithubCommitSerializer)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module Github
      class RepositoriesController < AuthenticatedController
        def index
          result = Api::V1::Github::ListRepositories.call(user: current_user)

          respond_with_service_result_collection(result, serializer: GithubRepositorySerializer)
        end
      end
    end
  end
end

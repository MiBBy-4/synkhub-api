# frozen_string_literal: true

module Api
  module V1
    module Github
      class StatsController < AuthenticatedController
        def index
          result = Api::V1::Github::ComputeStats.call(user: current_user)

          respond_with_service_result(result, serializer: GithubStatsSerializer)
        end
      end
    end
  end
end

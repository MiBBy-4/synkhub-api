# frozen_string_literal: true

module Api
  module V1
    module Github
      class Disconnect < BaseService
        attr_reader :user

        def initialize(user:)
          @user = user
        end

        def call
          user.update!(
            github_uid: nil,
            github_username: nil,
            github_access_token: nil,
            github_token_scope: nil
          )

          success(user)
        end

        private

        attr_writer :user
      end
    end
  end
end

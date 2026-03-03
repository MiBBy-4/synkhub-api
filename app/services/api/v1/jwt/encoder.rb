# frozen_string_literal: true

module Api
  module V1
    module Jwt
      class Encoder < BaseService
        EXPIRY = 24.hours

        attr_reader :user

        def initialize(user:)
          @user = user
        end

        def call
          payload = { user_id: user.id, exp: EXPIRY.from_now.to_i }
          token = JWT.encode(payload, secret_key, "HS256")
          success(token)
        end

        private

        attr_writer :user

        def secret_key
          ENV["JWT_SECRET"] || Rails.application.secret_key_base
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module Jwt
      class Decoder < BaseService
        attr_reader :token

        def initialize(token:)
          @token = token
        end

        def call
          payload = JWT.decode(token, secret_key, true, algorithm: "HS256").first
          user = User.find(payload["user_id"])
          success(user)
        rescue JWT::ExpiredSignature
          fail!("Token has expired")
        rescue JWT::DecodeError
          fail!("Invalid token")
        rescue ActiveRecord::RecordNotFound
          fail!("User not found")
        end

        private

        attr_writer :token

        def secret_key
          ENV["JWT_SECRET"] || Rails.application.secret_key_base
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module Authentication
      extend ActiveSupport::Concern

      private

      def authenticate_request!
        result = Api::V1::Jwt::Decoder.call(token: bearer_token)

        if result.success?
          @current_user = result.value
        else
          respond_with_unauthorized(result.error)
        end
      end

      def current_user
        @current_user
      end

      def bearer_token
        header = request.headers["Authorization"]
        header&.split&.last
      end
    end
  end
end

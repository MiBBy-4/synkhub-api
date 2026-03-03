# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ApplicationController
      def create
        result = Api::V1::Authentication::Authenticate.call(**session_params)

        respond_with_authenticated_service_result(result, serializer: UserSerializer, error_status: :unauthorized)
      end

      private

      def session_params
        params.permit(:email, :password).to_h.symbolize_keys
      end
    end
  end
end

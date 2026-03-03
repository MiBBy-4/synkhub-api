# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < ApplicationController
      def create
        result = Api::V1::Authentication::Register.call(**registration_params)

        respond_with_authenticated_service_result(result, serializer: UserSerializer, status: :created)
      end

      private

      def registration_params
        params.permit(:email, :password, :password_confirmation).to_h.symbolize_keys
      end
    end
  end
end

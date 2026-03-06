# frozen_string_literal: true

module Api
  module V1
    class GoogleCalendarController < AuthenticatedController
      def auth
        result = Api::V1::GoogleCalendar::GenerateAuthUrl.call(user: current_user)

        if result.success?
          render json: { data: { url: result.value }, meta: {} }
        else
          respond_with_unprocessable_entity(result.error)
        end
      end

      def callback
        result = Api::V1::GoogleCalendar::ExchangeCode.call(**callback_params)

        respond_with_service_result(result, serializer: UserSerializer)
      end

      def disconnect
        result = Api::V1::GoogleCalendar::Disconnect.call(user: current_user)

        respond_with_service_result(result, serializer: UserSerializer)
      end

      private

      def callback_params
        params.permit(:code, :state).to_h.symbolize_keys.merge(user: current_user)
      end
    end
  end
end

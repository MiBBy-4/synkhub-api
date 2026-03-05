# frozen_string_literal: true

module Api
  module V1
    module Users
      class PreferencesController < AuthenticatedController
        def show
          preference = current_user.user_preference || current_user.build_user_preference

          respond_with_serialized_resource(preference, serializer: UserPreferenceSerializer)
        end

        def update
          result = Api::V1::Users::UpsertPreferences.call(
            user: current_user,
            params: preference_params
          )

          respond_with_service_result(result, serializer: UserPreferenceSerializer)
        end

        private

        def preference_params
          params.permit(:email_digest_enabled, :email_digest_frequency, notification_event_types: []).to_h.symbolize_keys
        end
      end
    end
  end
end

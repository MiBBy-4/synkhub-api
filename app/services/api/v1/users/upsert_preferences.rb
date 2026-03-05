# frozen_string_literal: true

module Api
  module V1
    module Users
      class UpsertPreferences < BaseService
        attr_reader :user, :params

        def initialize(user:, params:)
          @user = user
          @params = params
        end

        def call
          preference = user.user_preference || user.build_user_preference
          preference.assign_attributes(params)

          if preference.save
            success(preference)
          else
            fail!(preference.errors.full_messages)
          end
        end

        private

        attr_writer :user, :params
      end
    end
  end
end

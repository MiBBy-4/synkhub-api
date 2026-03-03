# frozen_string_literal: true

module Api
  module V1
    module Authentication
      class Register < BaseService
        attr_reader :email, :password, :password_confirmation

        def initialize(email:, password:, password_confirmation:)
          @email = email
          @password = password
          @password_confirmation = password_confirmation
        end

        def call
          user = User.new(email: email, password: password, password_confirmation: password_confirmation)

          unless user.save
            return fail!(user.errors.full_messages.join(", "))
          end

          success(user)
        end

        private

        attr_writer :email, :password, :password_confirmation
      end
    end
  end
end

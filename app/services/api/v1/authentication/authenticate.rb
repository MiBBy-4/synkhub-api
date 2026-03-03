# frozen_string_literal: true

module Api
  module V1
    module Authentication
      class Authenticate < BaseService
        attr_reader :email, :password

        def initialize(email:, password:)
          @email = email
          @password = password
        end

        def call
          user = User.find_by(email: email)

          return fail!("User not found") unless user
          return fail!("Invalid email or password") unless user.authenticate(password)

          success(user)
        end

        private

        attr_writer :email, :password
      end
    end
  end
end

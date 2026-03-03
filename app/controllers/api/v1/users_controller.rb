# frozen_string_literal: true

module Api
  module V1
    class UsersController < AuthenticatedController
      def me
        respond_with_serialized_resource(current_user, serializer: UserSerializer)
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class AuthenticatedController < ApplicationController
      include Authentication

      before_action :authenticate_request!
    end
  end
end

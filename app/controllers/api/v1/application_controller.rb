# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ::ApplicationController
      include JsonResponders
    end
  end
end

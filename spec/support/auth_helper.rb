# frozen_string_literal: true

module AuthHelper
  def auth_headers_for(user)
    token = Api::V1::Jwt::Encoder.call(user: user).value
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end

# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      class VerifyGithubSignature < BaseService
        attr_reader :payload_body, :signature_header

        def initialize(payload_body:, signature_header:)
          @payload_body = payload_body
          @signature_header = signature_header
        end

        def call
          return fail!("Missing signature") if signature_header.blank?
          return fail!("Invalid signature") unless signature_header.match?(/\Asha256=[0-9a-f]{64}\z/)

          secret = ENV.fetch("GITHUB_WEBHOOK_SECRET")
          expected = "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload_body)}"

          unless ActiveSupport::SecurityUtils.secure_compare(expected, signature_header)
            return fail!("Invalid signature")
          end

          success(true)
        end

        private

        attr_writer :payload_body, :signature_header
      end
    end
  end
end

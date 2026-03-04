# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < ApplicationController
      def github
        request.body.rewind
        payload_body = request.body.read

        signature_result = Api::V1::Webhooks::VerifyGithubSignature.call(
          payload_body: payload_body,
          signature_header: request.headers["X-Hub-Signature-256"]
        )

        return respond_with_unauthorized(signature_result.error) unless signature_result.success?

        begin
          payload = JSON.parse(payload_body)
        rescue JSON::ParserError
          return respond_with_bad_request
        end

        ingest_result = Api::V1::Webhooks::IngestGithubEvent.call(
          event_type: request.headers["X-GitHub-Event"],
          delivery_id: request.headers["X-GitHub-Delivery"],
          payload: payload
        )

        respond_with_service_result(ingest_result, serializer: GithubWebhookEventSerializer)
      end
    end
  end
end

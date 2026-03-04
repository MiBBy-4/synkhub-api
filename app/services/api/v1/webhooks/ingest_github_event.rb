# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      class IngestGithubEvent < BaseService
        attr_reader :event_type, :delivery_id, :payload

        def initialize(event_type:, delivery_id:, payload:)
          @event_type = event_type
          @delivery_id = delivery_id
          @payload = payload
        end

        def call
          return fail!("Missing delivery ID") if delivery_id.blank?
          return fail!("Missing event type") if event_type.blank?

          unless GithubWebhookEvent::SUPPORTED_EVENTS.include?(event_type)
            return fail!("Unsupported event type: #{event_type}")
          end

          existing = GithubWebhookEvent.find_by(delivery_id: delivery_id)
          return success(existing) if existing

          event = GithubWebhookEvent.create!(
            event_type: event_type,
            delivery_id: delivery_id,
            action: payload["action"],
            payload: payload
          )

          ProcessGithubWebhookEventWorker.perform_async(event.id)

          success(event)
        rescue ActiveRecord::RecordNotUnique
          success(GithubWebhookEvent.find_by!(delivery_id: delivery_id))
        end

        private

        attr_writer :event_type, :delivery_id, :payload
      end
    end
  end
end

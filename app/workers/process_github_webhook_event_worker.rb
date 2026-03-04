# frozen_string_literal: true

class ProcessGithubWebhookEventWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true, queue: "webhooks"

  sidekiq_retries_exhausted do |msg, error|
    event = GithubWebhookEvent.find_by(id: msg["args"].first)
    event&.mark_failed!(error.message)
  end

  def perform(event_id)
    event = GithubWebhookEvent.find(event_id)

    return if event.status == GithubWebhookEvent::PROCESSED_STATUS

    event.mark_processing!

    # TODO: dispatch to event-type specific handlers
    event.mark_processed!
  end
end

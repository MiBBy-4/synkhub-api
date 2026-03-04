# frozen_string_literal: true

class GithubWebhookEventSerializer
  include Alba::Resource

  root_key :github_webhook_event

  attributes :id, :status
end

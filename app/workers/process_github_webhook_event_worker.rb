# frozen_string_literal: true

class ProcessGithubWebhookEventWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true, queue: "webhooks"

  HANDLERS = {
    "push" => Api::V1::Github::Handlers::HandlePush,
    "pull_request" => Api::V1::Github::Handlers::HandlePullRequest,
    "pull_request_review" => Api::V1::Github::Handlers::HandlePullRequestReview,
    "pull_request_review_comment" => Api::V1::Github::Handlers::HandlePullRequestReviewComment,
    "issues" => Api::V1::Github::Handlers::HandleIssues,
    "issue_comment" => Api::V1::Github::Handlers::HandleIssueComment,
    "check_run" => Api::V1::Github::Handlers::HandleCheckRun,
    "check_suite" => Api::V1::Github::Handlers::HandleCheckSuite,
    "create" => Api::V1::Github::Handlers::HandleCreate,
    "delete" => Api::V1::Github::Handlers::HandleDelete,
    "release" => Api::V1::Github::Handlers::HandleRelease,
    "workflow_run" => Api::V1::Github::Handlers::HandleWorkflowRun,
  }.freeze

  sidekiq_retries_exhausted do |msg, error|
    event = GithubWebhookEvent.find_by(id: msg["args"].first)
    event&.mark_failed!(error.message)
  end

  def perform(event_id)
    event = GithubWebhookEvent.find(event_id)

    return if event.status == GithubWebhookEvent::PROCESSED_STATUS

    event.mark_processing!

    handler_class = HANDLERS[event.event_type]
    if handler_class
      result = handler_class.call(event: event)
      raise result.error if result.error?
    end

    event.mark_processed!
  end
end

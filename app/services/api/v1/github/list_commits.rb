# frozen_string_literal: true

module Api
  module V1
    module Github
      class ListCommits < BaseService
        attr_reader :user

        MAX_EVENTS = 100
        MAX_COMMITS = 50

        Commit = Data.define(:sha, :message, :author_name, :author_login, :url, :timestamp, :repo_full_name, :branch, :pusher)

        def initialize(user:)
          @user = user
        end

        def call
          subscribed_repo_ids = user.github_repo_subscriptions.pluck(:github_repo_id)
          return success([]) if subscribed_repo_ids.empty?

          commits = extract_commits(subscribed_repo_ids)
          commits.sort_by! { |c| c.timestamp.to_s }.reverse!
          success(commits.first(MAX_COMMITS))
        end

        private

        attr_writer :user

        def extract_commits(subscribed_repo_ids)
          commits = []

          push_events.each do |event|
            payload = event.payload
            repo_id = payload.dig("repository", "id")
            next unless subscribed_repo_ids.include?(repo_id)

            commits.concat(build_commits(payload))
          end

          commits
        end

        def push_events
          GithubWebhookEvent
            .where(event_type: "push", status: GithubWebhookEvent::PROCESSED_STATUS)
            .order(created_at: :desc)
            .limit(MAX_EVENTS)
        end

        def build_commits(payload)
          repo_full_name = payload.dig("repository", "full_name")
          branch = payload.fetch("ref", "").sub("refs/heads/", "")
          pusher = payload.dig("pusher", "name")

          Array(payload["commits"]).map do |commit|
            Commit.new(
              sha: commit["id"],
              message: commit["message"],
              author_name: commit.dig("author", "name"),
              author_login: commit.dig("author", "username"),
              url: commit["url"],
              timestamp: commit["timestamp"],
              repo_full_name: repo_full_name,
              branch: branch,
              pusher: pusher
            )
          end
        end
      end
    end
  end
end

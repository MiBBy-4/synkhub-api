# frozen_string_literal: true

module Api
  module V1
    module Github
      module Handlers
        class HandleWorkflowRun < BaseHandler
          def call
            users = find_subscribed_users
            return success(nil) if users.empty?

            workflow_run = payload["workflow_run"]
            workflow_name = workflow_run["name"]
            conclusion = workflow_run["conclusion"]
            title = "Workflow '#{workflow_name}' completed (#{conclusion}) in #{repo_full_name}"
            url = workflow_run["html_url"]

            notifications = create_notifications!(users, title: title, url: url)
            success(notifications)
          end
        end
      end
    end
  end
end

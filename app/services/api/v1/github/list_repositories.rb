# frozen_string_literal: true

module Api
  module V1
    module Github
      class ListRepositories < BaseService
        attr_reader :user, :page, :limit

        GITHUB_API_URL = "https://api.github.com"

        PaginatedResult = Data.define(:items, :total, :page, :limit)

        def initialize(user:, page: 1, limit: 20)
          @user = user
          @page = page
          @limit = limit
        end

        def call
          return fail!("GitHub account not connected") unless user.github_connected?

          repos = fetch_repos
          total = repos.size
          offset = (page - 1) * limit
          paginated = repos[offset, limit] || []

          success(PaginatedResult.new(items: paginated, total: total, page: page, limit: limit))
        end

        private

        attr_writer :user, :page, :limit

        def fetch_repos
          all_repos = []
          gh_page = 1

          loop do
            response = api_connection.get("/user/repos", per_page: 100, sort: "updated", page: gh_page)
            repos = response.body
            break unless repos.is_a?(Array) && repos.any?

            all_repos.concat(repos.map { |r| normalize_repo(r) })
            break if repos.size < 100

            gh_page += 1
          end

          all_repos
        end

        def normalize_repo(repo)
          {
            id: repo["id"],
            full_name: repo["full_name"],
            name: repo["name"],
            private: repo["private"],
            owner_login: repo.dig("owner", "login"),
          }
        end

        def api_connection
          Faraday.new(url: GITHUB_API_URL) do |f|
            f.request :json
            f.response :json
            f.headers["Authorization"] = "Bearer #{user.github_access_token}"
            f.headers["User-Agent"] = "SynkHub"
          end
        end
      end
    end
  end
end

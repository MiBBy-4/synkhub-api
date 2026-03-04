# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubRepoSubscription, type: :model do
  subject { build(:github_repo_subscription) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:github_repo_id) }
    it { is_expected.to validate_uniqueness_of(:github_repo_id).scoped_to(:user_id) }
    it { is_expected.to validate_presence_of(:repo_full_name) }
  end
end

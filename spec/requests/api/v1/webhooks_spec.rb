# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Webhooks", type: :request do
  describe "POST /api/v1/webhooks/github" do
    let(:secret) { "test_webhook_secret" }
    let(:payload) { { "ref" => "refs/heads/main" }.to_json }
    let(:signature) { "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload)}" }
    let(:delivery_id) { SecureRandom.uuid }
    let(:headers) do
      {
        "Content-Type" => "application/json",
        "X-Hub-Signature-256" => signature,
        "X-GitHub-Event" => "push",
        "X-GitHub-Delivery" => delivery_id,
      }
    end

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_WEBHOOK_SECRET").and_return(secret)
      allow(ProcessGithubWebhookEventWorker).to receive(:perform_async)
      post "/api/v1/webhooks/github", params: payload, headers: headers
    end

    context "with a valid signature and event" do
      it "returns :ok and creates the event" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["status"]).to eq("pending")
        expect(ProcessGithubWebhookEventWorker).to have_received(:perform_async)
      end
    end

    context "with an invalid signature" do
      let(:signature) { "sha256=invalid" }

      it "returns :unauthorized" do
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("Invalid signature")
      end
    end

    context "with a missing signature" do
      let(:headers) do
        {
          "Content-Type" => "application/json",
          "X-GitHub-Event" => "push",
          "X-GitHub-Delivery" => delivery_id,
        }
      end

      it "returns :unauthorized" do
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("Missing signature")
      end
    end

    context "with a duplicate delivery" do
      before do
        post "/api/v1/webhooks/github", params: payload, headers: headers
      end

      it "returns :ok idempotently" do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

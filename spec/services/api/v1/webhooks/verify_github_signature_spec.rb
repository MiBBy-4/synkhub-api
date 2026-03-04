# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Webhooks::VerifyGithubSignature do
  describe ".call" do
    let(:result) { described_class.call(payload_body: payload_body, signature_header: signature_header) }
    let(:secret) { "It's a Secret to Everybody" }
    let(:payload_body) { "Hello, World!" }
    let(:signature_header) { "sha256=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17" }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_WEBHOOK_SECRET").and_return(secret)
    end

    context "with a valid signature" do
      it "returns success" do
        expect(result).to be_success
        expect(result.value).to be(true)
      end
    end

    context "with an invalid signature" do
      let(:signature_header) { "sha256=invalid" }

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Invalid signature")
      end
    end

    context "with a missing signature" do
      let(:signature_header) { nil }

      it "returns an error" do
        expect(result).to be_error
        expect(result.error).to eq("Missing signature")
      end
    end
  end
end

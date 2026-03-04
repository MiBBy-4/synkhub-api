# GitHub Webhook Signature Verification

## Overview

GitHub signs webhook payloads using HMAC SHA-256 with your webhook secret. Verify this signature to ensure the payload is authentic and hasn't been tampered with.

## How It Works

1. GitHub computes `HMAC-SHA256(secret, payload_body)` and sends it in the `X-Hub-Signature-256` header
2. The header value is prefixed with `sha256=` (e.g., `sha256=757107ea...`)
3. Your server computes the same HMAC and compares using a timing-safe function

## Ruby Implementation

```ruby
def verify_signature(payload_body, signature_header)
  secret = ENV.fetch("GITHUB_WEBHOOK_SECRET")
  expected = "sha256=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, payload_body)

  ActiveSupport::SecurityUtils.secure_compare(expected, signature_header)
end
```

### Reading the Raw Body in Rails

```ruby
request.body.rewind
payload_body = request.body.read
```

The `rewind` is necessary because Rails may have already read the body to parse params.

## Test Vector

Use this to verify your implementation:

| Field | Value |
|-------|-------|
| Secret | `It's a Secret to Everybody` |
| Payload | `Hello, World!` |
| Expected signature | `sha256=757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17` |

## Important

- **Never use `==`** for signature comparison — it's vulnerable to timing attacks
- Use `ActiveSupport::SecurityUtils.secure_compare` (Rails) or `Rack::Utils.secure_compare`
- Return `401 Unauthorized` if signature verification fails
- Always verify **before** processing the payload

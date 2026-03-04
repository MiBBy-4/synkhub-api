# GitHub Webhook Best Practices

## Respond Quickly

- Return a **2XX response within 10 seconds**
- GitHub will timeout and retry if the response takes too long
- Do **not** process the payload synchronously in the request

## Process Asynchronously

- Accept the webhook, store the event, and enqueue a background job (Sidekiq)
- This ensures fast response times and reliable processing with retries

```ruby
# Controller: accept and enqueue
event = GithubWebhookEvent.create!(...)
ProcessGithubWebhookEventWorker.perform_async(event.id)
head :ok

# Worker: process asynchronously
class ProcessGithubWebhookEventWorker
  include Sidekiq::Worker

  def perform(event_id)
    event = GithubWebhookEvent.find(event_id)
    # process...
  end
end
```

## Idempotency

- Use the `X-GitHub-Delivery` UUID to deduplicate events
- Store the delivery ID and check for duplicates before processing
- GitHub may send the same event multiple times (retries, redelivery)

## Signature Verification

- **Always verify** the `X-Hub-Signature-256` header before processing
- Use timing-safe comparison (`secure_compare`)
- Never use plain `==` — it's vulnerable to timing attacks
- See `signature-verification.md` for implementation details

## Error Handling

- Track failed events with status and error messages
- Use exponential backoff for job retries
- Log delivery IDs for debugging

## Security

- Keep webhook secrets in environment variables, never in code
- Rotate secrets periodically
- Use HTTPS for webhook endpoints in production
- Don't expose internal errors in webhook responses

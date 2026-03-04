# SynkHub API

Rails 8 API-only application with PostgreSQL, Sidekiq/Redis for background jobs.

For a high-level understanding of the project's goals, scope, and future direction, refer to `README.md`.

## Tech Stack

- Ruby 3.4.3, Rails 8.0.2
- PostgreSQL, Redis, Sidekiq
- JWT (stateless auth, 24h expiry, no refresh tokens)
- Faraday (HTTP client)
- Alba (JSON serialization)
- bcrypt (`has_secure_password`)
- RSpec, FactoryBot, Faker, Shoulda Matchers

## Running

Dockerized development. Container name: `synkhub-api-development-rails`.

```bash
docker exec synkhub-api-development-rails bundle exec rspec    # tests
docker exec synkhub-api-development-rails bundle install        # install gems
docker exec synkhub-api-development-rails bundle exec rails c   # console
```

**After each implementation**, run both commands inside the rails container:

```bash
docker exec synkhub-api-development-rails bundle exec rspec spec
docker exec synkhub-api-development-rails bundle exec rubocop -A
```

Fix any failures or offenses before considering the task done.

## Architecture

### Controller Hierarchy

```
ApplicationController (ActionController::API)
└── Api::V1::ApplicationController (includes JsonResponders)
    ├── Api::V1::RegistrationsController        (public)
    ├── Api::V1::SessionsController             (public)
    └── Api::V1::AuthenticatedController        (includes Authentication, before_action)
        └── Api::V1::UsersController            (auth required)
```

All API controllers live under `app/controllers/api/v1/`. Public endpoints inherit from `Api::V1::ApplicationController`. Protected endpoints inherit from `Api::V1::AuthenticatedController`.

When a controller references the same scope/association more than once, extract a private scope method (e.g. `github_notifications_scope`) to DRY it up:

```ruby
private

def github_notifications_scope
  current_user.github_notifications
end
```

All controllers that accept params **must** define a private strong parameters method. Never access `params[:key]` directly in actions — always go through the permit method:

```ruby
def create
  result = Api::V1::Authentication::Register.call(**registration_params)
  respond_with_authenticated_service_result(result, serializer: UserSerializer, status: :created)
end

private

def registration_params
  params.permit(:email, :password, :password_confirmation).to_h.symbolize_keys
end
```

### Services Pattern

All services inherit from `BaseService` (`app/services/base_service.rb`) and live under `app/services/api/v1/`.

Convention:
- Namespaced under `Api::V1` (e.g. `Api::V1::Authentication::Authenticate`)
- `attr_reader` in public scope for constructor params
- `@ivar` assignment in `initialize`
- `attr_writer` in private scope
- Use guard clauses: `return fail!("message") unless condition`
- Return via `success(value)` or `fail!(error_message)`
- Call via `Api::V1::MyService.call(args)` — returns the instance
- Check result with `result.success?` / `result.error?`
- Access return value with `result.value`, error with `result.error`

Example:

```ruby
module Api
  module V1
    module Authentication
      class Authenticate < BaseService
        attr_reader :email, :password

        def initialize(email:, password:)
          @email = email
          @password = password
        end

        def call
          user = User.find_by(email: email)

          return fail!("User not found") unless user
          return fail!("Invalid email or password") unless user.authenticate(password)

          success(user)
        end

        private

        attr_writer :email, :password
      end
    end
  end
end
```

### Serializers

Using Alba gem with `Serializer` naming convention (not `Resource`). Located in `app/serializers/`.

```ruby
class UserSerializer
  include Alba::Resource

  root_key :user

  attributes :id, :email
end
```

### JSON Response Format

All responses go through `Api::V1::JsonResponders` concern (`app/controllers/concerns/api/v1/json_responders.rb`).

**Success responses:**

```json
{ "data": { ... }, "meta": {} }
```

**Error responses:**

```json
{ "errors": ["Error message"] }
```

**Key responder methods:**

| Method | Use Case |
|--------|----------|
| `respond_with_service_result(result, serializer:)` | Standard CRUD — serializes `result.value` |
| `respond_with_authenticated_service_result(result, serializer:, status:, error_status:)` | Auth endpoints — serializes user + appends JWT token |
| `respond_with_serialized_resource(resource, serializer:)` | Direct resource rendering |
| `respond_with_serialized_resources_collection(resources, serializer:)` | Collection rendering |
| `respond_with_service_result_collection(result, serializer:)` | Service result with collection value |
| `respond_with_no_content_service_result(result)` | Delete/update with no body |
| `respond_with_unprocessable_entity(errors)` | 422 |
| `respond_with_unauthorized(message)` | 401 |
| `respond_with_not_found` | 404 |
| `respond_with_bad_request` | 400 |

Controllers should **never** use raw `render json:` — always use a responder method.

### Authentication

Stateless JWT. No sessions table, no server-side revocation. Logout is client-side (discard token).

- `Api::V1::Jwt::Encoder` — encodes user into JWT (24h expiry)
- `Api::V1::Jwt::Decoder` — decodes token, returns user
- `Api::V1::Authentication` concern — `authenticate_request!` before_action, extracts bearer token, sets `current_user`
- JWT secret: `ENV["JWT_SECRET"]` with `Rails.application.secret_key_base` fallback

### Workers

Background jobs use Sidekiq workers directly (`include Sidekiq::Worker`), **not** `ApplicationJob` / Active Job. Workers live under `app/workers/`, specs under `spec/workers/`.

Convention:
- Class name ends with `Worker` (not `Job`)
- `include Sidekiq::Worker`
- `sidekiq_options` for retry, queue, backtrace
- `sidekiq_retries_exhausted` block for failure handling (not `rescue`/`raise` in `perform`)
- Enqueue with `perform_async` (not `perform_later`)
- Keep `perform` body clean — no rescue/raise wrapping

Example:

```ruby
class ProcessGithubWebhookEventWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true, queue: "webhooks"

  sidekiq_retries_exhausted do |msg, error|
    event = GithubWebhookEvent.find_by(id: msg["args"].first)
    event&.mark_failed!(error.message)
  end

  def perform(event_id)
    event = GithubWebhookEvent.find(event_id)
    event.mark_processing!
    event.mark_processed!
  end
end
```

### Named Constants

Use named array constants when individual values are referenced elsewhere in the codebase. Values that are never referenced individually (like `SUPPORTED_EVENTS`) stay as plain arrays.

```ruby
STATUSES = [
  PENDING_STATUS = "pending",
  PROCESSING_STATUS = "processing",
  PROCESSED_STATUS = "processed",
  FAILED_STATUS = "failed",
].freeze
```

### Routes

Namespaced under `api/v1`:

```ruby
namespace :api do
  namespace :v1 do
    post "signup", to: "registrations#create"
    post "login",  to: "sessions#create"
    get  "me",     to: "users#me"
  end
end
```

Full route documentation with payloads and responses is in `docs/routes.md`. **Update `docs/routes.md` whenever routes, request params, or response shapes change.**

## RuboCop Style Rules

Run lint: `docker exec synkhub-api-development-rails bundle exec rubocop`

Key non-default rules that affect generated code:

- **Double quotes** for all strings — `"hello"`, never `'hello'`
- **No hash shorthand** — always `method(key: value)`, never `method(key:)` (Ruby 3.1 shorthand disabled)
- **Trailing commas** in multiline arrays and hashes
- **Bracket arrays** — `[:foo, :bar]` not `%i[foo bar]`; `["a", "b"]` not `%w[a b]`
- **Comparison over predicate** — `x > 0` not `x.positive?`
- **`expect { }.to change { }` block style** — not method style (`change(obj, :attr)`)
- **No `if`/`unless` modifier enforcement** — both inline and multiline forms are fine
- **No class documentation** required
- **`where(...)` over `exists?`** for Rails queries
- **Keyword args don't count** toward parameter list limits
- **Never disable RuboCop rules** with inline `# rubocop:disable` comments without explicit user approval. Instead, rename/refactor to satisfy the cop (e.g. `required_scope?` instead of `has_required_scope?`).

## Test Patterns

### General Rules

- `it` blocks contain **only** `expect`s — no method calls, no `reload`, no setup
- Setup (service calls, `reload`, mutations) goes in `before` blocks
- No hardcoded values — use `Faker` / `SecureRandom` for all generated data (including factories)
- Use `freeze_time` (not `travel_to`) for time-sensitive tests
- Use named constants (e.g. `GithubWebhookEvent::PENDING_STATUS`) instead of bare strings
- Use Faraday test stubs (not `Net::HTTP` mocks) for HTTP interactions
- Use `described_class` instead of hardcoding the class name in specs. If testing base class behavior through a concrete subclass, `RSpec.describe` the concrete class and use `described_class` for all calls.

### Request Specs

- HTTP request goes in `before` block, placed before all contexts at the `describe` level
- Use `let` for params — never `let!`
- If you need a record created before tests, create it in `before` block (not `let!`)
- Verify that the correct service is called (expect `.call` with args) or not called

```ruby
RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/login" do
    let(:params) { { email: email, password: password } }
    let(:email) { user.email }
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:user) { create(:user, password: password) }

    before do
      allow(Api::V1::Authentication::Authenticate).to receive(:call).and_call_original
      post "/api/v1/login", params: params
    end

    context "with valid credentials" do
      it "calls the service and returns :ok with token" do
        expect(Api::V1::Authentication::Authenticate).to have_received(:call)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]["token"]).to be_present
      end
    end

    context "with wrong password" do
      let(:password) { Faker::Internet.password(min_length: 8) }
      let(:user) { create(:user) }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
```

### Service Specs

- `result` as a `let` at the top of the `describe` block
- Entities via `let` (e.g. `let(:user) { create(:user) }`) — not in `before`
- Prefer one `it` block per context — use compound expectations
- When `result` causes side effects (e.g. DB updates), use `before { result }` and `before { user.reload }` so `it` blocks stay expect-only

```ruby
RSpec.describe Api::V1::Authentication::Authenticate do
  describe ".call" do
    let(:result) { described_class.call(email: email, password: password) }
    let(:email) { user.email }
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:user) { create(:user, password: password) }

    context "with valid credentials" do
      it "returns success with the user" do
        expect(result).to be_success
        expect(result.value).to eq(user)
      end
    end

    context "with wrong password" do
      let(:password) { Faker::Internet.password(min_length: 8) }
      let(:user) { create(:user) }

      it { expect(result).to be_error }
    end
  end
end
```

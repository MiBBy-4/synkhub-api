# frozen_string_literal: true

class UserPreferenceSerializer
  include Alba::Resource

  attributes :notification_event_types, :email_digest_enabled, :email_digest_frequency
end

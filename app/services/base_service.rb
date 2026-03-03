# frozen_string_literal: true

class BaseService
  attr_reader :value
  attr_accessor :error

  def initialize(*_params); end

  def call
    raise NotImplementedError
  end

  alias call! call

  def success?
    !error?
  end

  def error?
    error.present?
  end

  def success(value)
    self.value = value
  end

  alias success! success

  def fail!(error)
    self.error = error
  end

  def fail_with_rollback!(error)
    self.error = error

    raise ActiveRecord::Rollback
  end

  # Class methods to call the service directly (i.e. User::Create.call(create_params))
  def self.call(*, **)
    instance = new(*, **)

    instance.call

    instance
  end

  def self.call!(*, **)
    instance = new(*, **)

    instance.call!

    instance
  end

  private

  attr_writer :value
end

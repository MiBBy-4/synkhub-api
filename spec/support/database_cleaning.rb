# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    ApplicationRecord.connection.begin_transaction
  end

  config.after do
    postgresql_connection = ApplicationRecord.connection
    postgresql_connection.rollback_transaction if postgresql_connection.transaction_open?
  end

  # Use `with_nested_transaction: true` to test code that uses nested transactions to check that records
  # will not be created due to some failure (i.e. ActiveRecord::Rollback call).
  # This will use `SAVEPOINT` to create a nested transaction.
  config.before(:example, :with_nested_transaction) do
    ApplicationRecord.connection.begin_transaction(joinable: false)
  end

  config.after(:example, :with_nested_transaction) do
    postgresql_connection = ApplicationRecord.connection
    postgresql_connection.rollback_transaction if postgresql_connection.transaction_open?
  end
end

#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database to be ready..."
bundle exec rails runner "
max_attempts = 30
attempts = 0
begin
  ActiveRecord::Base.establish_connection
  ActiveRecord::Base.connection.active?
  puts 'Database is ready!'
rescue => e
  attempts += 1
  if attempts < max_attempts
    puts \"Database not ready yet (attempt #{attempts}/#{max_attempts}): #{e.message}. Retrying in 2s...\"
    sleep 2
    retry
  else
    puts 'Failed to connect to database.'
    exit 1
  end
end
"

# Run database migrations
echo "Running database migrations..."
bundle exec rails db:migrate RAILS_ENV=production

# Load default data (non-interactive if REDMINE_LANG is set)
echo "Loading default configuration data..."
export REDMINE_LANG=${REDMINE_LANG:-en}
bundle exec rails redmine:load_default_data RAILS_ENV=production

# Start the rails server
echo "Starting Rails server..."
bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000} -e production

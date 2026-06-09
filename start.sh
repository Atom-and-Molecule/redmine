#!/bin/bash
set -e

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL environment variable is not set!"
  echo "Please ensure you have added a PostgreSQL database service in Railway and linked its environment variables to this service."
  exit 1
fi

# Log SMTP setup status for debugging
echo "Checking SMTP/Email configuration..."
DETECTED_SMTP_HOST=""
if [ -n "$SMTP_ADDRESS" ]; then
  DETECTED_SMTP_HOST="$SMTP_ADDRESS"
elif [ -n "$MAILGUN_SMTP_SERVER" ]; then
  DETECTED_SMTP_HOST="$MAILGUN_SMTP_SERVER"
elif [ -n "$MAILGUN_SMTP_HOST" ]; then
  DETECTED_SMTP_HOST="$MAILGUN_SMTP_HOST"
fi

if [ -n "$DETECTED_SMTP_HOST" ]; then
  echo "=> SMTP configuration detected: host='$DETECTED_SMTP_HOST'"
else
  echo "=> WARNING: No SMTP environment variables detected. Email notifications will be disabled."
fi

# Wait for database to be ready
echo "Waiting for database to be ready..."
bundle exec rails runner -e production "
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

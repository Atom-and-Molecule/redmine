#!/bin/bash
set -e

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

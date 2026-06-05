# frozen_string_literal: true
require 'securerandom'

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random.
RedmineApp::Application.config.secret_key_base = ENV['SECRET_KEY_BASE'] || SecureRandom.hex(40)

# frozen_string_literal: true

# Dynamically set defaults for key settings using environment variables,
# particularly useful for Railway deployments.
Rails.application.config.to_prepare do
  if defined?(Setting) && Setting.respond_to?(:available_settings)
    if Setting.available_settings['mail_from']
      # Default to SMTP_FROM, or SMTP_USER_NAME / SMTP_USER / SMTP_USERNAME / MAILGUN_SMTP_LOGIN / MAILGUN_SMTP_USER if it looks like an email address, otherwise keep default
      from_email = ENV['SMTP_FROM']
      if from_email.blank?
        smtp_user = ENV['SMTP_USER_NAME'] || ENV['SMTP_USER'] || ENV['SMTP_USERNAME'] ||
                    ENV['MAILGUN_SMTP_LOGIN'] || ENV['MAILGUN_SMTP_USER'] ||
                    ENV['SENDGRID_USERNAME']

        if smtp_user.blank? && (smtp_url = ENV['SMTP_URL'] || ENV['MAIL_URL']).present?
          begin
            require 'uri'
            require 'cgi'
            uri = URI.parse(smtp_url.strip)
            smtp_user = CGI.unescape(uri.user) if uri.user
          rescue
          end
        end

        if smtp_user.present? && smtp_user.include?('@')
          from_email = smtp_user
        end
      end
      Setting.available_settings['mail_from']['default'] = from_email if from_email.present?
    end

    if Setting.available_settings['host_name']
      Setting.available_settings['host_name']['default'] = ENV['RAILWAY_PUBLIC_DOMAIN'] || ENV['HOST_NAME'] || Setting.available_settings['host_name']['default']
    end

    if Setting.available_settings['protocol']
      if ENV['RAILWAY_PUBLIC_DOMAIN'] || ENV['PROTOCOL'] == 'https'
        Setting.available_settings['protocol']['default'] = 'https'
      end
    end

    # Log SMTP configuration status to Rails logs/stdout during initialization
    msg_env_name = "=> [SMTP Debug] Current Rails Environment: #{Rails.env}"
    puts msg_env_name
    Rails.logger.info msg_env_name

    has_email = ActionMailer::Base.perform_deliveries
    if has_email
      msg = "=> [SMTP Debug] Email delivery configured! Host: #{ActionMailer::Base.smtp_settings[:address]}"
      puts msg
      Rails.logger.info msg
    else
      msg = "=> [SMTP Debug] WARNING: Email delivery is NOT configured!"
      puts msg
      Rails.logger.warn msg
      # Safely print names of available environment variables to help the user identify what is set
      env_keys = ENV.keys.select { |k| k.include?('SMTP') || k.include?('MAIL') || k.include?('SENDGRID') }
      msg_env = "=> [SMTP Debug] Available email env vars: #{env_keys.join(', ')}"
      puts msg_env
      Rails.logger.warn msg_env
    end
  end
end

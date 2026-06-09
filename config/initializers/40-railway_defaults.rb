# frozen_string_literal: true

# Dynamically set defaults for key settings using environment variables,
# particularly useful for Railway deployments.
Rails.application.config.to_prepare do
  if defined?(Setting) && Setting.respond_to?(:available_settings)
    if Setting.available_settings['mail_from']
      # Default to SMTP_FROM, or SMTP_USER_NAME if it looks like an email address, otherwise keep default
      from_email = ENV['SMTP_FROM']
      if from_email.blank? && ENV['SMTP_USER_NAME'].present? && ENV['SMTP_USER_NAME'].include?('@')
        from_email = ENV['SMTP_USER_NAME']
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
  end
end

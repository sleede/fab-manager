# frozen_string_literal: true

require 'version'

Sentry.init do |config|
  config.excluded_exceptions += ['Pundit::NotAuthorizedError']

  config.before_send = lambda do |event, hint|
    if hint[:exception].is_a?(Redis::CommandError) && hint[:exception].message == 'LOADING Redis is loading the dataset in memory'
      nil
    else
      event
    end
  end

  if ENV.fetch('ENABLE_SENTRY', 'false') == 'true'
    config.dsn = 'https://b7dd8812fd0d4d4eac907001e2efec86@o486357.ingest.sentry.io/4504446773886976'
  end

  config.breadcrumbs_logger = [:active_support_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 0.01
  config.environment = Rails.env
  config.release = Version.current
end

Sentry.configure_scope do |scope|
  scope.set_tags(instance: ENV.fetch('DEFAULT_HOST'))
end

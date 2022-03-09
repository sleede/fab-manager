# frozen_string_literal: true

redis_host = ENV['REDIS_HOST'] || 'localhost'
redis_url = "redis://#{redis_host}:6379"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)

  # load sidekiq-cron schedule config
  schedule_file = 'config/schedule.yml'

  if File.exist?(schedule_file)
    rendered_schedule_file = ERB.new(File.read(schedule_file)).result
    Sidekiq::Cron::Job.load_from_hash YAML.safe_load(rendered_schedule_file)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq::Extensions.enable_delay!

# Quieting logging in the test environment
if Rails.env.test?
  require 'sidekiq/testing'
  Sidekiq.logger.level = Logger::ERROR
end

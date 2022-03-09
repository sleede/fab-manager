# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-scheduler'

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

  config.on(:startup) do
    # load sidekiq-scheduler schedule config
    schedule_file = 'config/schedule.yml'
    if File.exist?(schedule_file)
      rendered_schedule_file = ERB.new(File.read(schedule_file)).result
      Sidekiq.schedule = YAML.safe_load(rendered_schedule_file)
      SidekiqScheduler::Scheduler.instance.reload_schedule!
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

# Quieting logging in the test environment
if Rails.env.test?
  require 'sidekiq/testing'
  Sidekiq.logger.level = Logger::ERROR
end

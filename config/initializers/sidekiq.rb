# If ENV['REDIS_URL'] = nil, then url = redis://localhost:6379/0

if Rails.env.staging?
  namespace = "fabmanager_staging"
else
  namespace = "fabmanager"
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], namespace: namespace }
end

# load sidekiq-cron schedule config
schedule_file = "config/schedule.yml"

if File.exists?(schedule_file)
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end

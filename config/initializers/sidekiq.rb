if Rails.env.staging?
  namespace = "fablab_staging"
else
  namespace = "fablab"
end

redis_host = ENV["REDIS_HOST"] || 'localhost'
redis_url = "redis://#{redis_host}:6379"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, namespace: namespace }

  # load sidekiq-cron schedule config
  schedule_file = "config/schedule.yml"

  if File.exists?(schedule_file)
    rendered_schedule_file = ERB.new(File.read(schedule_file)).result
    Sidekiq::Cron::Job.load_from_hash YAML.load(rendered_schedule_file)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, namespace: namespace }
end

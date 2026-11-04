# frozen_string_literal: true

# Run in the reviewed application runtime. Output only counts and digests, never job arguments.
require 'sidekiq/api'
require 'digest'
require 'json'

Sidekiq.configure_client { |config| config.redis = { url: ENV.fetch('REDIS_URL') } } if ENV['REDIS_URL']

if ENV['FM_PG_QUEUE_ACTION'] == 'quiet'
  Sidekiq::ProcessSet.new.each(&:quiet!)
  puts JSON.generate(quiet: true)
else
  digest = Digest::SHA256.new
  queues = Sidekiq::Queue.all.sort_by(&:name)
  queues.each do |queue|
    digest.update(queue.name)
    queue.each { |job| digest.update(job.value) }
  end
  sets = [Sidekiq::ScheduledSet.new, Sidekiq::RetrySet.new, Sidekiq::DeadSet.new]
  sets.each do |set|
    set.each { |job| digest.update("#{job.score}:#{job.value}") }
  end
  puts JSON.generate(busy: Sidekiq::ProcessSet.new.sum { |process| process['busy'].to_i },
                     queued: queues.sum(&:size), scheduled: sets[0].size, retry: sets[1].size,
                     dead: sets[2].size, sha256: digest.hexdigest)
end

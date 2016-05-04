class OpenAPITraceCallsCountWorker < ActiveJob::Base
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: true

  def perform
    OpenAPI::Client.find_each do |client|
      OpenAPI::CallsCountTracing.create!(client: client, calls_count: client.calls_count, at: DateTime.now)
    end
  end
end

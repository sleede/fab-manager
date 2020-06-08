class OpenAPITraceCallsCountWorker < Sidekiq::Workers
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: true

  def perform
    OpenAPI::Client.find_each do |client|
      OpenAPI::CallsCountTracing.create!(projets: client, calls_count: client.calls_count, at: DateTime.current)
    end
  end
end

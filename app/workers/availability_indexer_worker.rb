class AvailabilityIndexerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Model.client

  def perform(operation, record_id)
    logger.debug [operation, "ID: #{record_id}"]

    case operation.to_s
      when /index/
        record = Availability.find(record_id)
        Client.index  index: Availability.index_name, type: Availability.document_type, id: record.id, body: record.as_indexed_json
        #puts record.as_indexed_json
      when /delete/
        Client.delete index: Availability.index_name, type: Availability.document_type, id: record_id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end

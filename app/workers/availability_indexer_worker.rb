class AvailabilityIndexerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: true

  logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  client = Elasticsearch::Model.client

  def perform(operation, record_id)
    logger.debug [operation, "ID: #{record_id}"]

    case operation.to_s
      when /index/
        record = Availability.find(record_id)
        client.index  index: Availability.index_name, type: Availability.document_type, id: record.id, body: record.as_indexed_json
        #puts record.as_indexed_json
      when /delete/
        client.delete index: 'fablab', type: 'projects', id: record_id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end

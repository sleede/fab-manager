class AvailabilityIndexerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Model.client

  def perform(operation, record_id)
    logger.debug [operation, "ID: #{record_id}"]

    case operation.to_s
      when /index/
        begin
          record = Availability.find(record_id)
          Client.index  index: Availability.index_name, type: Availability.document_type, id: record.id, body: record.as_indexed_json
        rescue ActiveRecord::RecordNotFound
          STDERR.puts "Availability id(#{record_id}) will not be indexed in ElasticSearch as it does not exists anymore in database"
        end
      when /delete/
        begin
          Client.delete index: Availability.index_name, type: Availability.document_type, id: record_id
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          STDERR.puts "Availability id(#{record_id}) will not be deleted form ElasticSearch as it has not been already indexed"
        end
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end

class ProjectIndexerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Model.client

  def perform(operation, record_id)
    logger.debug [operation, "ID: #{record_id}"]

    case operation.to_s
      when /index/
        record = Project.find(record_id)
        Client.index  index: Project.index_name, type: Project.document_type, id: record.id, body: record.to_json
      when /delete/
        Client.delete index: 'fablab', type: 'availabilities', id: record_id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end

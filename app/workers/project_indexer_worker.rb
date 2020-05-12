# frozen_string_literal: true

# Index the projects to ElasticSearch
class ProjectIndexerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: true

  def perform(operation, record_id)
    logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
    client = Elasticsearch::Model.client

    logger&.debug [operation, "ID: #{record_id}"]

    case operation.to_s
    when /index/
      record = Project.find(record_id)
      client.index  index: Project.index_name, type: Project.document_type, id: record.id, body: record.as_indexed_json
    when /delete/
      client.delete index: Project.index_name, type: Project.document_type, id: record_id
    else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end

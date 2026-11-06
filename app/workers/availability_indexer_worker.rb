# frozen_string_literal: true

# Apply availability projections asynchronously, preserving idempotent deletes.
class AvailabilityIndexerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: true

  def perform(operation, record_id)
    logger.debug [operation, "ID: #{record_id}"]

    case operation.to_s
    when /index/
      begin
        record = Availability.find(record_id)
        SearchIndex.index_availability(record: record)
      rescue ActiveRecord::RecordNotFound
        logger.warn "Availability id(#{record_id}) will not be indexed in ElasticSearch as it does not exists anymore in database"
      end
    when /delete/
      begin
        SearchIndex.delete(family: 'availabilities', id: record_id)
      rescue Elastic::Transport::Transport::Errors::NotFound
        logger.warn "Availability id(#{record_id}) will not be deleted form ElasticSearch as it has not been already indexed"
      end
    else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end

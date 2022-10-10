# frozen_string_literal: true

# Clean the existing statistics
class Statistics::CleanerService
  include Statistics::Concerns::HelpersConcern

  class << self
    def clean_stat(options = default_options)
      client = Elasticsearch::Model.client
      %w[Account Event Machine Project Subscription Training User Space].each do |o|
        model = "Stats::#{o}".constantize
        client.delete_by_query(
          index: model.index_name,
          type: model.document_type,
          body: {
            query: {
              terms: {
                date: (to_date(options[:start_date]).to_date..to_date(options[:end_date]).to_date)
                        .to_a
                        .map { |d| format_date(d) }
              }
            }
          }
        )
      end
    end
  end
end

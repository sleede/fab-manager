# frozen_string_literal: true

# Clean the existing statistics
class Statistics::CleanerService
  include Statistics::Concerns::HelpersConcern

  class << self
    def clean_stat(options = default_options)
      client = Elasticsearch::Model.client
      %w[Account Event Machine Project Subscription Training User Space Order].each do |o|
        model = "Stats::#{o}".constantize
        dates = (to_date(options[:start_date]).to_date..to_date(options[:end_date]).to_date).to_a
        # elasticsearch does not support more than 1024 query arguments
        dates.each_slice(1024) do |slice_dates|
          client.delete_by_query(
            index: model.index_name,
            type: model.document_type,
            body: {
              query: {
                terms: {
                  date: slice_dates.map { |d| format_date(d) }
                }
              }
            }
          )
        end
      end
    end
  end
end

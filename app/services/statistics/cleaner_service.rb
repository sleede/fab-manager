# frozen_string_literal: true

# Clean the existing statistics
class Statistics::CleanerService
  include Statistics::Concerns::HelpersConcern

  class << self
    def clean_stat(options = default_options)
      ElasticsearchMigrationGuard.rebuild!(options)
      SearchIndex::STAT_FAMILIES.each do |family|
        dates = (to_date(options[:start_date]).to_date..to_date(options[:end_date]).to_date).to_a
        # elasticsearch does not support more than 1024 query arguments
        dates.each_slice(1024) do |slice_dates|
          SearchIndex.delete_by_query(
            family: family,
            query: {
              terms: {
                date: slice_dates.map { |d| format_date(d) }
              }
            }
          )
        end
      end
    end
  end
end

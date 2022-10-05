# frozen_string_literal: true

# This will generate statistics indicators. Those will be saved in the ElasticSearch database
class Statistics::BuilderService
  class << self
    def generate_statistic(options = default_options)
      # remove data exists
      Statistics::CleanerService.clean_stat(options)

      Statistics::Builders::SubscriptionsBuilderService.build(options)
      Statistics::Builders::ReservationsBuilderService.build(options)
      Statistics::Builders::MembersBuilderService.build(options)
      Statistics::Builders::ProjectsBuilderService.build(options)
    end

    private

    def default_options
      yesterday = 1.day.ago
      {
        start_date: yesterday.beginning_of_day,
        end_date: yesterday.end_of_day
      }
    end
  end
end

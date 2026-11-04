# frozen_string_literal: true

# Elasticsearch operations remain on the existing 5.6 cluster.
namespace :fablab do
  namespace :es do
    desc '(re)Build ElasticSearch fablab base for stats'
    task build_stats: :environment do
      next unless Setting.get('statistics_module')

      SearchIndex.rebuild_statistics!
    end

    desc 'add event filters to statistics'
    task add_event_filters: :environment do
      SearchIndex.add_event_filters
    end

    desc 'add spaces reservations to statistics'
    task add_spaces: :environment do
      SearchIndex.add_spaces_mapping
    end

    desc 'sync all/one availabilities in ElasticSearch index'
    task :build_availabilities_index, [:id] => :environment do |_task, args|
      SearchIndex.ensure_availability_mapping
      if args.id
        AvailabilityIndexerWorker.perform_async(:index, args.id)
      else
        Availability.pluck(:id).each do |availability_id|
          AvailabilityIndexerWorker.perform_async(:index, availability_id)
        end
      end
    end

    desc '(re)generate statistics in ElasticSearch for the past period. Use 0 to generate for today'
    task :generate_stats, [:period] => :environment do |_task, args|
      raise 'FATAL ERROR: You must pass a number of days (=> past period) OR a date to generate statistics' unless args.period

      unless Setting.get('statistics_module')
        print 'Statistics are disabled. Do you still want to generate? (y/N) '
        confirm = $stdin.gets.chomp
        raise 'Interrupted by user' unless confirm == 'y'
      end

      worker = PeriodStatisticsWorker.new
      worker.perform(args.period)
    end
  end
end

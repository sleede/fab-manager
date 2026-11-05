# frozen_string_literal: true

# New installation schema setup never deletes indices. Existing data needs its own migration.
namespace :fablab do
  namespace :es do
    desc 'Initialize or validate the Elasticsearch 9 schema and aliases without deleting data'
    task initialize: :environment do
      SearchIndex.initialize_schema!
    end

    desc 'Read-only validation of an already initialized Elasticsearch 9 schema'
    task validate: :environment do
      SearchIndex::Schema.validate!(SearchIndex::Connection.client)
    end

    desc 'Ensure statistics schema (non-destructive compatibility name for setup)'
    task build_stats: :environment do
      SearchIndex.initialize_schema! if Setting.get('statistics_module')
    end

    desc 'Validate the event statistics mapping'
    task add_event_filters: :initialize

    desc 'Validate the space statistics mapping'
    task add_spaces: :initialize

    desc 'Synchronize all/one SQL availability to its Elasticsearch projection'
    task :build_availabilities_index, [:id] => :environment do |_task, args|
      SearchIndex.initialize_schema!
      ids = args.id ? [args.id] : Availability.pluck(:id)
      ids.each { |id| AvailabilityIndexerWorker.perform_async(:index, id) }
    end

    desc '(re)generate statistics for the past period, removing that period first; use 0 for today'
    task :generate_stats, [:period] => :environment do |_task, args|
      raise 'FATAL ERROR: You must pass a number of days (=> past period) OR a date to generate statistics' unless args.period

      unless Setting.get('statistics_module')
        print 'Statistics are disabled. Do you still want to generate? (y/N) '
        confirm = $stdin.gets.chomp
        raise 'Interrupted by user' unless confirm == 'y'
      end

      PeriodStatisticsWorker.new.perform(args.period)
    end
  end
end

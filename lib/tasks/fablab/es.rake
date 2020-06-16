# frozen_string_literal: true

# ElasticSearch relative tasks
namespace :fablab do
  namespace :es do
    desc '(re)Build ElasticSearch fablab base for stats'
    task build_stats: :environment do
      delete_stats_index
      create_stats_index
      create_stats_mappings
      add_event_filters
    end

    def delete_stats_index
      puts 'DELETE stats'
      `curl -XDELETE http://#{ENV['ELASTICSEARCH_HOST']}:9200/stats`
    end

    def create_stats_index
      puts 'PUT index stats'
      `curl -XPUT http://#{ENV['ELASTICSEARCH_HOST']}:9200/stats -d'
    {
      "settings" : {
        "index" : {
          "number_of_replicas" : 0
        }
      }
    }
    '`
    end

    def create_stats_mappings
      %w[account event machine project subscription training user space].each do |stat|
        puts "PUT Mapping stats/#{stat}"
        `curl -XPUT http://#{ENV['ELASTICSEARCH_HOST']}:9200/stats/#{stat}/_mapping -d '
      {
         "properties": {
            "type": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "subType": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "date": {
               "type": "date"
            },
            "name": {
               "type": "string",
               "index" : "not_analyzed"
            }
         }
      }';`
      end
    end

    desc 'add event filters to statistics'
    task add_event_filters: :environment do
      add_event_filters
    end

    def add_event_filters
      `curl -XPUT http://#{ENV['ELASTICSEARCH_HOST']}:9200/stats/event/_mapping -d '
      {
         "properties": {
            "ageRange": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "eventTheme": {
               "type": "string",
               "index" : "not_analyzed"
            }
         }
      }';`
    end


    desc 'add spaces reservations to statistics'
    task add_spaces: :environment do
      `curl -XPUT http://#{ENV['ELASTICSEARCH_HOST']}:9200/stats/space/_mapping -d '
      {
         "properties": {
            "type": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "subType": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "date": {
               "type": "date"
            },
            "name": {
               "type": "string",
               "index" : "not_analyzed"
            }
         }
      }';`
    end

    desc 'sync all/one project in ElasticSearch index'
    task :build_projects_index, [:id] => :environment do |_task, args|
      client = Project.__elasticsearch__.client

      # ask if we delete the index
      print 'Delete all projects in ElasticSearch index? (y/n) '
      confirm = STDIN.gets.chomp
      if confirm == 'y'
        client.delete_by_query(
          index: Project.index_name,
          type: Project.document_type,
          conflicts: 'proceed',
          body: { query: { match_all: {} } }
        )
      end

      # create index if not exists
      Project.__elasticsearch__.create_index! force: true unless client.indices.exists? index: Project.index_name

      # index requested documents
      if args.id
        ProjectIndexerWorker.perform_async(:index, id)
      else
        Project.pluck(:id).each do |project_id|
          ProjectIndexerWorker.perform_async(:index, project_id)
        end
      end
    end

    desc 'sync all/one availabilities in ElasticSearch index'
    task :build_availabilities_index, [:id] => :environment do |_task, args|
      client = Availability.__elasticsearch__.client
      # create index if not exists
      Availability.__elasticsearch__.create_index! force: true unless client.indices.exists? index: Availability.index_name
      # delete doctype if exists
      if client.indices.exists_type? index: Availability.index_name, type: Availability.document_type
        client.indices.delete_mapping index: Availability.index_name, type: Availability.document_type
      end
      # create doctype
      client.indices.put_mapping index: Availability.index_name,
                                 type: Availability.document_type,
                                 body: Availability.mappings.to_hash

      # verify doctype creation was successful
      if client.indices.exists_type? index: Availability.index_name, type: Availability.document_type
        puts "[ElasticSearch] #{Availability.index_name}/#{Availability.document_type} successfully created with its mapping."

        # index requested documents
        if args.id
          AvailabilityIndexerWorker.perform_async(:index, id)
        else
          Availability.pluck(:id).each do |availability_id|
            AvailabilityIndexerWorker.perform_async(:index, availability_id)
          end
        end
      else
        puts "[ElasticSearch] An error occurred while creating #{Availability.index_name}/#{Availability.document_type}. " \
           'Please check your ElasticSearch configuration.'
        puts "\nCancelling..."
      end
    end


    desc '(re)generate statistics in ElasticSearch for the past period. Use 0 to generate for today'
    task :generate_stats, [:period] => :environment do |_task, args|
      raise 'FATAL ERROR: You must pass a number of days (=> past period) OR a date to generate statistics' unless args.period

      days = date_to_days(args.period)
      puts "\n==> generating statistics for the last #{days} days <==\n"
      if days.zero?
        StatisticService.new.generate_statistic(start_date: DateTime.current.beginning_of_day, end_date: DateTime.current.end_of_day)
      else
        days.times.each do |i|
          StatisticService.new.generate_statistic(start_date: i.day.ago.beginning_of_day, end_date: i.day.ago.end_of_day)
        end
      end
    end

    def date_to_days(value)
      date = Date.parse(value.to_s)
      (DateTime.current.to_date - date).to_i
    rescue ArgumentError
      value.to_i
    end
  end
end

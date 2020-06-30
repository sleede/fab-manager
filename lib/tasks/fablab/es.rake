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

      unless Setting.get('statistics_module')
        print 'Statistics are disabled. Do you still want to generate? (y/N) '
        confirm = STDIN.gets.chomp
        raise 'Interrupted by user' unless confirm == 'y'
      end

      worker = PeriodStatisticsWorker.new
      worker.perform(args.period)
    end
  end
end

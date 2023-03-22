# frozen_string_literal: false

namespace :db do
  desc 'Convert development DB to Rails test fixtures'
  task :to_fixtures, [:table] => :environment do |_task, args|
    tables_to_skip = %w[ar_internal_metadata delayed_jobs schema_info schema_migrations].freeze

    begin
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.tables.each do |table_name|
        next if tables_to_skip.include?(table_name)
        next if args.table && args.table != table_name

        conter = '000'
        file_path = Rails.root.join("test/fixtures/test/#{table_name}.yml")
        File.open(file_path, 'w') do |file|
          rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name}")
          data = rows.each_with_object({}) do |record, hash|
            suffix = record['id'].presence || conter.succ!
            hash["#{table_name.singularize}_#{suffix}"] = record
          end
          puts "Writing table '#{table_name}' to '#{file_path}'"
          file.write(data.to_yaml)
        end
      end
    ensure
      ActiveRecord::Base.connection&.close
    end
  end
end

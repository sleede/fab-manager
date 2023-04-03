# frozen_string_literal: false

namespace :db do
  # Usage example:
  #     RAILS_ENV=test rails db:to_fixtures[chained_elements]
  desc 'Convert development DB to Rails test fixtures'
  task :to_fixtures, [:table] => :environment do |_task, args|
    tables_to_skip = %w[ar_internal_metadata delayed_jobs schema_info schema_migrations].freeze

    begin
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.tables.each do |table_name|
        next if tables_to_skip.include?(table_name)
        next if args.table && args.table != table_name

        counter = '000'
        file_path = Rails.root.join("test/fixtures/#{table_name}.yml")
        File.open(file_path, File::WRONLY | File::CREAT) do |file|
          rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name}")
          data = rows.each_with_object({}) do |record, hash|
            suffix = record['id'].presence || counter.succ!
            # FIXME, this is broken with jsonb columns: it records a String but a Hash must be saved
            hash["#{table_name.singularize}#{suffix}"] = yamlize(record, rows.column_types)
          end
          puts "Writing table '#{table_name}' to '#{file_path}'"
          file.write(data.to_yaml)
        end
      end
    ensure
      ActiveRecord::Base.connection&.close
    end
  end

  def yamlize(record, column_types)
    record.each_with_object({}) do |(key, value), hash|
      hash[key] = column_types.include?(key) && column_types[key].type == :jsonb ? JSON.parse(value) : value
    end
  end
end

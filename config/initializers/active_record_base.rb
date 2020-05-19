# frozen_string_literal: true

ActiveRecord::Base.class_eval do
  def dump_fixture
    fixture_file = "#{Rails.root}/test/fixtures/#{self.class.table_name}.yml"
    File.open(fixture_file, 'a') do |f|
      f.puts({ "#{self.class.table_name.singularize}_#{id}" => attributes }.
        to_yaml.sub!(/---\s?/, "\n"))
    end
  end

  def self.dump_fixtures
    fixture_file = "#{Rails.root}/test/fixtures/#{table_name}.yml"
    mode = (File.exist?(fixture_file) ? 'a' : 'w')
    File.open(fixture_file, mode) do |f|

      if attribute_names.include?('id')
        all.each do |instance|
          f.puts({ "#{table_name.singularize}_#{instance.id}" => instance.attributes }.to_yaml.sub!(/---\s?/, "\n"))
        end
      else
        all.each_with_index do |instance, i|
          f.puts({ "#{table_name.singularize}_#{i}" => instance.attributes }.to_yaml.sub!(/---\s?/, "\n"))
        end
      end
    end
  end
end

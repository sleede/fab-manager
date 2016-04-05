ActiveRecord::Base.class_eval do
  def dump_fixture
    fixture_file = "#{Rails.root}/test/fixtures/#{self.class.table_name}.yml"
    File.open(fixture_file, "a") do |f|
      f.puts({ "#{self.class.table_name.singularize}_#{id}" => attributes }.
        to_yaml.sub!(/---\s?/, "\n"))
    end
  end

  def self.dump_fixtures
    fixture_file = "#{Rails.root}/test/fixtures/#{self.table_name}.yml"
    File.open(fixture_file, "w") do |f|
      self.all.each do |instance|
        f.puts({ "#{self.table_name.singularize}_#{instance.id}" => instance.attributes }.to_yaml.sub!(/---\s?/, "\n"))
      end
    end
  end
end

require 'test_helper'

class ExportTest < ActiveSupport::TestCase
  test 'export must have a category' do
    e = Export.new({export_type: 'global', user: User.first, query: '{"query":{"bool":{"must":[{"range":{"date":{"gte":"2016-06-25T02:00:00+02:00","lte":"2016-07-25T23:59:59+02:00"}}}]}}}'})
    assert e.invalid?
  end

  test 'export generate an XLSX file' do
    e = Export.create({category: 'statistics', export_type: 'global', user: User.first, query: '{"query":{"bool":{"must":[{"range":{"date":{"gte":"2016-06-25T02:00:00+02:00","lte":"2016-07-25T23:59:59+02:00"}}}]}}}'})
    e.save!
    VCR.use_cassette("export_generate_an_xlsx_file") do
      assert_export_xlsx e
    end
  end
end

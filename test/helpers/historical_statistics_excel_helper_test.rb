# frozen_string_literal: true

require 'test_helper'

class HistoricalStatisticsExcelHelperTest < ActiveSupport::TestCase
  include ExcelHelper

  test 'optional historical list and date fields render blank cells' do
    data = []
    styles = []
    types = []
    format_xlsx_cell(nil, data, styles, types, source_data_type: 'list')
    format_xlsx_cell(nil, data, styles, types, source_data_type: 'date', date_format: 7)
    assert_equal ['', nil], data
    assert_equal [nil, 7], styles
    assert_equal %i[string date], types
  end

  test 'populated lists dates and numeric zero keep their values and types' do
    data = []
    styles = []
    types = []
    format_xlsx_cell([{ 'name' => 'Historical machine' }], data, styles, types, source_data_type: 'list')
    format_xlsx_cell('2019-03-10', data, styles, types, source_data_type: 'date', date_format: 7)
    format_xlsx_cell(0, data, styles, types, source_data_type: 'number')
    assert_equal ['Historical machine', Date.new(2019, 3, 10), 0], data
    assert_equal %i[string date float], types
  end

  test 'invalid populated optional fields remain visible errors' do
    assert_raises(NoMethodError) { format_xlsx_cell(false, [], [], [], source_data_type: 'list') }
    assert_raises(Date::Error) { format_xlsx_cell('invalid', [], [], [], source_data_type: 'date') }
  end
end

# frozen_string_literal: true

require 'test_helper'
require 'rubyXL'

module Exports; end

class Exports::StatisticsExportTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'export machine reservations statistics to Excel' do
    Stats::Machine.refresh_index!
    # Build the stats for the June 2015, a machine reservation should have happened at the time
    ::Statistics::BuilderService.generate_statistic({ start_date: '2015-06-01'.to_date.beginning_of_day,
                                                      end_date: '2015-06-30'.to_date.end_of_day })
    # Create a new export
    post '/stats/machine/export',
         params: {
           type_key: 'booking',
           body: '{"query":{"bool":{"must":[{"term":{"type":"booking"}},{"range":{"date":{"gte":"2015-06-01T02:00:00+02:00",' \
                 '"lte":"2015-06-30T23:59:59+02:00"}}}]}},"sort":[{"date":{"order":"desc"}}],"aggs":{"total_ca":{"sum":{"field":"ca"}}, ' \
                 '"average_age":{"avg":{"field":"age"}},"total_stat":{"sum":{"field":"stat"}}}}'
         }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the export was created correctly
    res = json_response(response.body)
    e = Export.where(id: res[:export_id]).first
    assert_not_nil e, 'Export was not created in database'

    # Run the worker
    Stats::Machine.refresh_index!
    worker = StatisticsExportWorker.new
    worker.perform(e.id)

    # notification
    assert_not_empty Notification.where(attached_object: e)

    # resulting XLSX file
    assert FileTest.exist?(e.file), 'XLSX file was not generated'
    workbook = RubyXL::Parser.parse(e.file)

    # test worksheet
    assert_not_nil workbook[StatisticIndex.find_by(es_type_key: 'machine').label]

    # test data
    reservation = Reservation.find(2)
    wb = workbook[StatisticIndex.find_by(es_type_key: 'machine').label]
    assert_equal 1, wb.sheet_data[0][1].value
    assert_equal 15.0, wb.sheet_data[1][1].value
    assert_equal reservation.user.statistic_profile.age.to_i, wb.sheet_data[2][1].value
    assert_equal reservation.created_at.to_date, wb.sheet_data[5][0].value.to_date
    assert_equal reservation.user.profile.full_name, wb.sheet_data[5][1].value
    assert_equal reservation.user.email, wb.sheet_data[5][2].value
    assert_equal reservation.user.profile.phone, wb.sheet_data[5][3].value
    assert_equal I18n.t("export.#{reservation.user.statistic_profile.str_gender}"), wb.sheet_data[5][4].value
    assert_equal reservation.user.statistic_profile.age.to_i, wb.sheet_data[5][5].value
    assert_equal reservation.reservable.name, wb.sheet_data[5][6].value
    assert_equal reservation.invoice_items.first.invoice.total / 100.0, wb.sheet_data[5][7].value

    # Clean XLSX file
    require 'fileutils'
    FileUtils.rm(e.file)
  end

  test 'export global statistics to Excel' do
    Stats::Machine.refresh_index!
    # Build the stats for the June 2015
    ::Statistics::BuilderService.generate_statistic({ start_date: '2015-06-01'.to_date.beginning_of_day,
                                                      end_date: '2015-06-30'.to_date.end_of_day })
    # Create a new export
    post '/stats/global/export',
         params: {
           type_key: 'booking',
           body: '{"query":{"bool":{"must":[{"range":{"date":{"gte":"2015-06-01T02:00:00+02:00","lte":"2015-06-30T23:59:59+02:00"}}}]}}}'
         }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the export was created correctly
    res = json_response(response.body)
    e = Export.where(id: res[:export_id]).first
    assert_not_nil e, 'Export was not created in database'

    # Run the worker
    worker = StatisticsExportWorker.new
    worker.perform(e.id)

    # notification
    assert_not_empty Notification.where(attached_object: e)

    # resulting XLSX file
    assert FileTest.exist?(e.file), 'XLSX file was not generated'
    workbook = RubyXL::Parser.parse(e.file)

    # test worksheets
    assert_equal StatisticIndex.where(table: true).includes(:statistic_types).map(&:statistic_types).flatten.count,
                 workbook.worksheets.length
  end
end

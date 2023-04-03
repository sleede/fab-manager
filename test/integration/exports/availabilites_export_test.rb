# frozen_string_literal: true

require 'test_helper'
require 'rubyXL'

module Exports; end

class Exports::AvailabilitiesExportTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'export availabilities to Excel' do
    # First, we create a new export
    get '/api/availabilities/export_index.xlsx'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the export was created correctly
    res = json_response(response.body)
    e = Export.where(id: res[:export_id]).first
    assert_not_nil e, 'Export was not created in database'

    # Run the worker
    worker = AvailabilitiesExportWorker.new
    worker.perform(e.id)

    # notification
    assert_not_empty Notification.where(attached_object: e)

    # resulting XLSX file
    assert FileTest.exist?(e.file), 'XLSX file was not generated'
    workbook = RubyXL::Parser.parse(e.file)

    # test worksheets
    assert_not_nil workbook[I18n.t('export_availabilities.machines')]
    assert_not_nil workbook[I18n.t('export_availabilities.trainings')]
    assert_not_nil workbook[I18n.t('export_availabilities.events')]
    if Setting.get('spaces_module')
      assert_not_nil workbook[I18n.t('export_availabilities.spaces')]
    else
      assert_nil workbook[I18n.t('export_availabilities.spaces')]
    end

    # test data
    availability = Availability.find(13)
    machines = workbook[I18n.t('export_availabilities.machines')]
    assert_equal availability.start_at.to_date, machines.sheet_data[1][0].value.to_date
    assert_equal I18n.l(availability.start_at, format: '%A').capitalize, machines.sheet_data[1][1].value
    assert_match(/^#{availability.start_at.strftime('%H:%M')} - /, machines.sheet_data[1][2].value)
    assert_includes availability.machines.map(&:name), machines.sheet_data[1][3].value

    # Clean XLSX file
    require 'fileutils'
    FileUtils.rm(e.file)
  end
end

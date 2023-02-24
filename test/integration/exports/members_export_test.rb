# frozen_string_literal: true

require 'test_helper'
require 'rubyXL'

module Exports; end

class Exports::MembersExportTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'export members to Excel' do
    # First, we create a new export
    get '/api/members/export_members.xlsx'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the export was created correctly
    res = json_response(response.body)
    e = Export.where(id: res[:export_id]).first
    assert_not_nil e, 'Export was not created in database'

    # Run the worker
    worker = UsersExportWorker.new
    worker.perform(e.id)

    # notification
    assert_not_empty Notification.where(attached_object: e)

    # resulting XLSX file
    assert FileTest.exist?(e.file), 'XLSX file was not generated'
    workbook = RubyXL::Parser.parse(e.file)

    # test worksheet
    assert_not_nil workbook[I18n.t('export_members.members')]

    # test data
    wb = workbook[I18n.t('export_members.members')]
    member = User.find(wb.sheet_data[1][0].value)
    assert_equal (member.is_allow_newsletter ? 1 : 0), wb.sheet_data[1][5].value

    # Clean XLSX file
    require 'fileutils'
    FileUtils.rm(e.file)
  end
end

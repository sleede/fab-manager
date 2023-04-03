# frozen_string_literal: true

require 'test_helper'
require 'rubyXL'

module Exports; end

class Exports::SubscriptionsExportTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'export subscriptions to Excel' do
    # First, we create a new export
    get '/api/members/export_subscriptions.xlsx'

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
    assert_not_nil workbook[I18n.t('export_subscriptions.subscriptions')]

    # test data
    subscription = Subscription.find(1)
    wb = workbook[I18n.t('export_subscriptions.subscriptions')]
    assert_equal subscription.user.id, wb.sheet_data[1][0].value
    assert_equal subscription.plan.human_readable_name(group: true), wb.sheet_data[1][3].value
    assert_equal subscription.created_at.to_date, wb.sheet_data[1][5].value.to_date

    # Clean XLSX file
    require 'fileutils'
    FileUtils.rm(e.file)
  end
end

# frozen_string_literal: true

require 'coveralls'
Coveralls.wear!('rails')

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'action_dispatch'
require 'rails/test_help'
require 'vcr'
require 'sidekiq/testing'
require 'minitest/reporters'
require 'helpers/archive_helper'
require 'helpers/invoice_helper'
require 'helpers/payment_schedule_helper'
require 'fileutils'

# We remove this constraint before running tests, otherwise it will prevent loading the fixtures into the DB
ActiveRecord::Base.connection.execute("DROP RULE IF EXISTS accounting_periods_del_protect ON #{AccountingPeriod.arel_table.name};")

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('sk_test_testfaketestfaketestfake') { Setting.get('stripe_secret_key') }
  config.filter_sensitive_data('pk_test_faketestfaketestfaketest') { Setting.get('stripe_public_key') }
  config.filter_sensitive_data('github-oauth-app-id') { ENV.fetch('OAUTH_CLIENT_ID') }
  config.filter_sensitive_data('github-oauth-app-secret') { ENV.fetch('OAUTH_CLIENT_SECRET') }
  config.filter_sensitive_data('oidc-client-id') { ENV.fetch('OIDC_CLIENT_ID') }
  config.filter_sensitive_data('oidc-client-secret') { ENV.fetch('OIDC_CLIENT_SECRET') }
  config.ignore_request { |req| URI(req.uri).port == 9200 || URI(req.uri).host == '127.0.0.1' }
end

Sidekiq::Testing.fake!
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true)] unless ENV['RM_INFO']

class ActiveSupport::TestCase
  include ActionDispatch::TestProcess
  include ArchiveHelper
  include InvoiceHelper
  include PaymentScheduleHelper

  # Add more helper methods to be used by all tests here...
  ActiveRecord::Migration.check_pending!
  fixtures :all

  def json_response(body)
    JSON.parse(body, symbolize_names: true)
  end

  def default_headers
    { 'Accept' => Mime[:json], 'Content-Type' => Mime[:json].to_s }
  end

  def upload_headers
    { 'Accept' => Mime[:json], 'Content-Type' => Mime[:multipart_form].to_s }
  end

  def open_api_headers(token)
    { 'Accept' => Mime[:json], 'Content-Type' => Mime[:json].to_s, 'Authorization' => "Token token=#{token}" }
  end

  def stripe_payment_method(error: nil)
    number = '4242424242424242'
    exp_month = 4
    exp_year = Time.current.next_year.year
    cvc = '314'

    case error
    when /card_declined/
      number = '4000000000000002'
    when /incorrect_number/
      number = '4242424242424241'
    when /invalid_expiry_month/
      exp_month = 15
    when /invalid_expiry_year/
      exp_year = 1964
    when /invalid_cvc/
      cvc = '99'
    when /require_3ds/
      number = '4000002760003184'
    end

    Stripe::PaymentMethod.create(
      {
        type: 'card',
        card: {
          number: number,
          exp_month: exp_month,
          exp_year: exp_year,
          cvc: cvc
        }
      },
      { api_key: Setting.get('stripe_secret_key') }
    ).id
  end

  # Force the statistics export generation worker to run NOW and check the resulting file generated.
  # Delete the file afterwards.
  # @param export {Export}
  def assert_export_xlsx(export)
    assert_not_nil export, 'Export was not created'

    if export.category == 'statistics'
      export_worker = StatisticsExportWorker.new
      export_worker.perform(export.id)

      assert File.exist?(export.file), 'Export XLSX was not generated'

      File.delete(export.file)
    else
      skip('Unable to test export which is not of the category "statistics"')
    end
  end

  def assert_dates_equal(expected, actual, msg = nil)
    assert_not_nil actual, msg
    assert_equal expected.to_date, actual.to_date, msg
  end

  def assert_datetimes_near(expected, actual, msg = nil)
    assert_not_nil actual, msg
    assert_in_delta expected.to_i, actual.to_i, 1, msg
  end
end

class ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!
end

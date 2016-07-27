ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'vcr'
require 'sidekiq/testing'
require 'minitest/reporters'

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
end

Sidekiq::Testing.fake!
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new({ color: true })]




class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...

  fixtures :all

  def json_response(body)
    JSON.parse(body, symbolize_names: true)
  end

  def default_headers
    { 'Accept' => Mime::JSON, 'Content-Type' => Mime::JSON.to_s }
  end

  def stripe_card_token(error: nil)
    number = "4242424242424242"
    exp_month = 4
    exp_year = DateTime.now.next_year.year
    cvc = "314"

    case error
    when /card_declined/
      number = "4000000000000002"
    when /incorrect_number/
      number = "4242424242424241"
    when /invalid_expiry_month/
      exp_month = 15
    when /invalid_expiry_year/
      exp_year = 1964
    when /invalid_cvc/
      cvc = "99"
    end

    Stripe::Token.create(card: {
      number: number,
        exp_month: exp_month,
        exp_year: exp_year,
        cvc:  cvc
      },
    ).id
  end

  # Force the invoice generation worker to run NOW and check the resulting file generated.
  # Delete the file afterwards.
  # @param invoice {Invoice}
  def assert_invoice_pdf(invoice)
    assert_not_nil invoice, 'Invoice was not created'

    invoice_worker = InvoiceWorker.new
    invoice_worker.perform(invoice.id)

    assert File.exist?(invoice.file), 'Invoice PDF was not generated'

    File.delete(invoice.file)
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
end

class ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!
end

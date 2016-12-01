require 'coveralls'
Coveralls.wear!('rails')

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

    # now we check the file content
    reader = PDF::Reader.new(invoice.file)
    assert_equal 1, reader.page_count # single page invoice

    ht_amount = invoice.total
    page = reader.pages.first
    lines = page.text.scan(/^.+/)
    lines.each do |line|
      # check that the numbers printed into the PDF file match the total stored in DB
      if line.include? I18n.t('invoices.total_amount')
        assert_equal invoice.total / 100.0, parse_amount_from_invoice_line(line), 'Invoice total rendered in the PDF file does not match'
      end

      # check that the VAT was correctly applied if it was configured
      if line.include? I18n.t('invoices.including_total_excluding_taxes')
        ht_amount = parse_amount_from_invoice_line(line)
      end
    end

    if Setting.find_by(name: 'invoice_VAT-active').value == 'true'
      vat_rate = Setting.find_by({name: 'invoice_VAT-rate'}).value.to_f
      computed_ht = sprintf('%.2f', (invoice.total / (vat_rate / 100 + 1)) / 100.0).to_f

      assert_equal computed_ht, ht_amount, 'Total excluding taxes rendered in the PDF file is not computed correctly'
    else
      assert_equal invoice.total, ht_amount, 'VAT information was rendered in the PDF file despite that VAT was disabled'
    end
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

  private

  # Parse a line of text read from a PDF file and return the price included inside
  # Line of text should be of form 'Label              $10.00'
  # @returns {float}
  def parse_amount_from_invoice_line line
    line[line.rindex(' ')+1..-1].tr(I18n.t('number.currency.format.unit'), '').to_f
  end
end

class ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!
end

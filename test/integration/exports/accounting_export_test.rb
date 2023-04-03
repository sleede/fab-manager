# frozen_string_literal: true

require 'test_helper'
module Exports; end

class Exports::AccountingExportTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'export accounting period to ACD software' do
    # First, we create a new export
    post '/api/accounting/export',
         params: {
           query: {
             columns: %w[journal_code date account_code account_label piece line_label
                         debit_origin credit_origin debit_euro credit_euro lettering],
             encoding: 'ISO-8859-1',
             date_format: '%d/%m/%Y',
             start_date: '2012-03-12T00:00:00.000Z',
             end_date: Time.current.utc.iso8601,
             label_max_length: 50,
             decimal_separator: ',',
             export_invoices_at_zero: false
           }.to_json.to_s,
           extension: 'csv',
           type: 'acd',
           key: ';'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the export was created correctly
    res = json_response(response.body)
    e = Export.find(res[:export_id])
    assert_not_nil e, 'Export was not created in database'

    # Run the worker
    worker = AccountingExportWorker.new
    worker.perform(e.id)

    # notification
    assert_not_empty Notification.where(attached_object: e)

    # resulting CSV file
    assert FileTest.exist?(e.file), 'CSV file was not generated'
    require 'csv'
    data = CSV.read(e.file, headers: true, col_sep: e.key)

    # test values
    first_invoice = Invoice.first
    # first line = payment line
    check_payment_line(first_invoice, data[0])
    # second line = sold item line
    check_item_line(first_invoice, first_invoice.invoice_items.first, data[1])

    # ensure invoice 4 is not exported (0€ invoice)
    zero_invoice = Invoice.find(4)
    assert_nil(data.map { |line| line[I18n.t('accounting_export.piece')] }.find { |document| document == zero_invoice.reference },
               'Invoice at 0 should not be exported')

    # test with a reservation invoice
    machine_invoice = Invoice.find(5)
    check_payment_line(machine_invoice, data[6])
    check_item_line(machine_invoice, machine_invoice.invoice_items.first, data[7])

    # test with a shop order invoice (local payment)
    shop_invoice = Invoice.find(5811)
    check_payment_line(shop_invoice, data[10])
    check_item_line(shop_invoice, shop_invoice.invoice_items.first, data[11])
    check_item_line(shop_invoice, shop_invoice.invoice_items.last, data[12])

    # Clean CSV file
    require 'fileutils'
    FileUtils.rm(e.file)
  end

  def check_payment_line(invoice, payment_line)
    check_entry_date(invoice, payment_line)
    check_client_accounts(invoice, payment_line)
    check_entry_label(invoice, payment_line)
    check_document(invoice, payment_line)

    if invoice.wallet_transaction_id.nil?
      assert_equal invoice.total / 100.00, payment_line[I18n.t('accounting_export.debit_origin')].to_f,
                   'Origin debit amount does not match'
      assert_equal invoice.total / 100.00, payment_line[I18n.t('accounting_export.debit_euro')].to_f, 'Euro debit amount does not match'
    else
      warn "WARNING: unable to test accurately accounting export: invoice #{invoice.id} is using wallet"
    end

    assert_equal 0, payment_line[I18n.t('accounting_export.credit_origin')].to_f, 'Credit origin amount does not match'
    assert_equal 0, payment_line[I18n.t('accounting_export.credit_euro')].to_f, 'Credit euro amount does not match'
  end

  def check_item_line(invoice, invoice_item, item_line)
    check_sales_journal_code(item_line)
    check_entry_date(invoice, item_line)

    check_subscription_accounts(invoice, item_line)
    check_reservation_accounts(invoice, item_line)
    check_document(invoice, item_line)
    check_entry_label(invoice, item_line)

    assert_equal invoice_item.amount / 100.00, item_line[I18n.t('accounting_export.credit_origin')].to_f,
                 'Origin credit amount does not match'
    assert_equal invoice_item.amount / 100.00, item_line[I18n.t('accounting_export.credit_euro')].to_f, 'Euro credit amount does not match'

    assert_equal 0, item_line[I18n.t('accounting_export.debit_origin')].to_f, 'Debit origin amount does not match'
    assert_equal 0, item_line[I18n.t('accounting_export.debit_euro')].to_f, 'Debit euro amount does not match'
  end

  def check_sales_journal_code(line)
    journal_code = Setting.get('accounting_sales_journal_code')
    assert_equal journal_code, line[I18n.t('accounting_export.journal_code')], 'Wrong journal code'
  end

  def check_entry_date(invoice, line)
    entry_date = invoice.created_at.to_date
    assert_equal entry_date, Time.zone.parse(line[I18n.t('accounting_export.date')]).to_date, 'Wrong date'
  end

  def check_client_accounts(invoice, client_line)
    if invoice.wallet_transaction && invoice.wallet_amount.positive?
      wallet_client_code = Setting.get('accounting_payment_wallet_code')
      assert_equal wallet_client_code, client_line[I18n.t('accounting_export.account_code')], 'Account code for wallet client is wrong'

      wallet_client_label = Setting.get('accounting_payment_wallet_label')
      assert_equal wallet_client_label, client_line[I18n.t('accounting_export.account_label')], 'Account label for wallet client is wrong'

      wallet_client_journal = Setting.get('accounting_payent_wallet_journal_code')
      assert_equal wallet_client_journal, client_line[I18n.t('accounting_export.journal_code')], 'Journal code for wallet client is wrong'
    end
    mean = invoice.paid_by_card? ? 'card' : 'other'

    client_code = Setting.get("accounting_payment_#{mean}_code")
    assert_equal client_code, client_line[I18n.t('accounting_export.account_code')], 'Account code for client is wrong'
    # the test above fails randomly... we don't know why!

    client_label = Setting.get("accounting_payment_#{mean}_label")
    assert_equal client_label, client_line[I18n.t('accounting_export.account_label')], 'Account label for client is wrong'

    client_journal = Setting.get("accounting_payment_#{mean}_journal_code")
    assert_equal client_journal, client_line[I18n.t('accounting_export.journal_code')], 'Journal code for client is wrong'
  end

  def check_subscription_accounts(invoice, item_line)
    return unless invoice.subscription_invoice?

    subscription_code = Setting.get('accounting_subscription_code')
    assert_equal subscription_code, item_line[I18n.t('accounting_export.account_code')], 'Account code for subscription is wrong'

    subscription_label = Setting.get('accounting_subscription_label')
    assert_equal subscription_label, item_line[I18n.t('accounting_export.account_label')], 'Account label for subscription is wrong'
  end

  def check_reservation_accounts(invoice, item_line)
    return unless invoice.main_item.object_type == 'Reservation'

    code = Setting.get("accounting_#{invoice.main_item.object.reservable_type}_code")
    assert_equal code, item_line[I18n.t('accounting_export.account_code')], 'Account code for reservation is wrong'

    label = Setting.get("accounting_#{invoice.main_item.object.reservable_type}_label")
    assert_equal label, item_line[I18n.t('accounting_export.account_label')], 'Account label for reservation is wrong'
  end

  def check_document(invoice, line)
    assert_equal(invoice.reference, line[I18n.t('accounting_export.piece')], 'Document (invoice reference) is wrong')
  end

  def check_entry_label(invoice, line)
    if invoice.subscription_invoice?
      assert_match I18n.t('accounting_summary.subscription_abbreviation'),
                   line[I18n.t('accounting_export.line_label')],
                   'Entry label does not contains the reference to the subscription'
    end
    if invoice.main_item.object_type == 'Reservation'
      assert_match I18n.t("accounting_summary.#{invoice.main_item.object.reservable_type}_reservation_abbreviation"),
                   line[I18n.t('accounting_export.line_label')],
                   'Entry label does not contains the reference to the reservation'
    end
    if invoice.main_item.object_type == 'WalletTransaction'
      assert_match I18n.t('accounting_summary.wallet_abbreviation'),
                   line[I18n.t('accounting_export.line_label')],
                   'Entry label does not contains the reference to the wallet'
    end

    return unless invoice.main_item.object_type == 'OrderItem'

    assert_match I18n.t('accounting_summary.shop_order_abbreviation'),
                 line[I18n.t('accounting_export.line_label')],
                 'Entry label does not contains the reference to the order'
  end
end

# frozen_string_literal: true

# Periodically build the accounting data (AccountingLine) from the Invoices & Avoirs
class AccountingWorker
  include Sidekiq::Worker

  attr_reader :performed

  def perform(action = :yesterday, *params)
    send(action, *params)
  end

  def today
    service = Accounting::AccountingService.new
    start = DateTime.current.beginning_of_day
    finish = DateTime.current.end_of_day
    ids = service.build(start, finish)
    @performed = "today: #{start} -> #{finish}; invoices: #{ids}"
  end

  def yesterday
    service = Accounting::AccountingService.new
    start = DateTime.yesterday.beginning_of_day
    finish = DateTime.yesterday.end_of_day
    ids = service.build(start, finish)
    @performed = "yesterday: #{start} -> #{finish}; invoices: #{ids}"
  end

  def invoices(invoices_ids)
    # clean
    AccountingLine.where(invoice_id: invoices_ids).delete_all
    # build
    service = Accounting::AccountingService.new
    invoices = Invoice.where(id: invoices_ids)
    ids = service.build_from_invoices(invoices)
    @performed = "invoices: #{ids}"
  end

  def all
    # clean
    AccountingLine.delete_all
    # build
    service = Accounting::AccountingService.new
    ids = service.build_from_invoices(Invoice.all)
    @performed = "all: #{ids}"
  end
end

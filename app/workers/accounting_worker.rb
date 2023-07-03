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
    start = Time.current.beginning_of_day
    finish = Time.current.end_of_day
    ids = service.build(start, finish)
    @performed = "today: #{start} -> #{finish}; invoices: #{ids}"
  end

  def yesterday
    service = Accounting::AccountingService.new
    start = 1.day.ago.beginning_of_day
    finish = 1.day.ago.end_of_day
    ids = service.build(start, finish)
    @performed = "yesterday: #{start} -> #{finish}; invoices: #{ids}"
  end

  def invoices(invoices_ids)
    # build
    service = Accounting::AccountingService.new
    invoices = Invoice.where(id: invoices_ids)
    ids = service.build_from_invoices(invoices)
    @performed = "invoices: #{ids}"
  end

  def all
    # build
    service = Accounting::AccountingService.new
    ids = service.build_from_invoices(Invoice.all)
    @performed = "all: #{ids}"
  end
end

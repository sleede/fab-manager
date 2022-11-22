# frozen_string_literal: true

# Periodically build the accounting data (AccountingLine) from the Invoices & Avoirs
class AccountingWorker
  include Sidekiq::Worker

  def perform(action = :today, *params)
    send(action, *params)
  end

  def today
    service = Accounting::AccountingService.new
    service.build(DateTime.current.beginning_of_day, DateTime.current.end_of_day)
  end

  def invoices(invoices_ids)
    service = Accounting::AccountingService.new
    invoices = Invoice.where(id: invoices_ids)
    service.build_from_invoices(invoices)
  end

  def all
    service = Accounting::AccountingService.new
    service.build_from_invoices(Invoice.all)
  end
end

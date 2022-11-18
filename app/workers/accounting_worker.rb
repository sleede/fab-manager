# frozen_string_literal: true

# Periodically build the accounting data (AccountingLine) from the Invoices & Avoirs
class AccountingWorker
  include Sidekiq::Worker

  def perform
    service = Accounting::AccountingService.new
    service.build(DateTime.current.beginning_of_day, DateTime.current.end_of_day)
  end
end

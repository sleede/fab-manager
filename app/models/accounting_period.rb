# frozen_string_literal: true

# AccountingPeriod is a period of N days (N > 0) which as been closed by an admin
# to prevent writing new accounting lines (invoices & refunds) during this period of time.
class AccountingPeriod < ActiveRecord::Base
  before_destroy { false }
  before_update { false }

  validates :start_at, :end_at, :closed_at, :closed_by, presence: true
  validates_with DateRangeValidator
  validates_with PeriodOverlapValidator

  def delete
    false
  end
end

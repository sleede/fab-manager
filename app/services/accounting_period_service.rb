# frozen_string_literal: true

# Provides methods for accessing AccountingPeriods properties
class AccountingPeriodService

  def find_last_period
    AccountingPeriod.where(end_at: AccountingPeriod.select('max(end_at)')).first
  end
end

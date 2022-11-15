# frozen_string_literal: true

# module definition
module Accounting; end

# Provides methods for accessing AccountingPeriods properties
class Accounting::AccountingPeriodService
  class << self
    def find_last_period
      AccountingPeriod.where(end_at: AccountingPeriod.select('max(end_at)')).first
    end

    def all_periods_with_users
      AccountingPeriod.joins("INNER JOIN #{User.arel_table.name} ON users.id = accounting_periods.closed_by
                              INNER JOIN #{Profile.arel_table.name} ON profiles.user_id = users.id")
                      .select("#{AccountingPeriod.arel_table.name}.*,
                               #{Profile.arel_table.name}.first_name,
                               #{Profile.arel_table.name}.last_name")
                      .order('start_at DESC')
    end
  end
end

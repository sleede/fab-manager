class AccountingPeriod < ActiveRecord::Base
  before_destroy { false }
  before_update { false }

  def delete
    false
  end
end

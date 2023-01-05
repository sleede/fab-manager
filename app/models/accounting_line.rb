# frozen_string_literal: false

# Stores an accounting datum related to an invoice, matching the French accounting system (PCG).
# Accounting data are configured by settings starting with accounting_* and by AdvancedAccounting
class AccountingLine < ApplicationRecord
  belongs_to :invoice
  belongs_to :invoicing_profile
end

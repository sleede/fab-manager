# frozen_string_literal: false

# Stores an accounting datum related to an invoice, matching the French accounting system (PCG).
# Accounting data are configured by settings starting with accounting_* and by AdvancedAccounting
class AccountingLine < ApplicationRecord
  belongs_to :invoice
  belongs_to :invoicing_profile

  def invoice_payment_method
    # if the invoice was 100% payed with the wallet ...
    return 'wallet' if (!invoice.wallet_amount.nil? && (invoice.wallet_amount - invoice.total == 0)) || invoice.payment_method == 'wallet'

    # else
    if invoice.paid_by_card?
      'card'
    else
      'other'
    end
  end
end

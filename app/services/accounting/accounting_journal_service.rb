# frozen_string_literal: false

# module definition
module Accounting; end

# fetch the journal code matching the given resource
class Accounting::AccountingJournalService
  def initialize
    @journal_codes = {
      sales: Setting.get('accounting_sales_journal_code') || '',
      wallet: Setting.get('accounting_wallet_journal_code') || '',
      vat: Setting.get('accounting_VAT_journal_code') || '',
      payment: {
        card: Setting.get('accounting_payment_card_journal_code') || '',
        wallet: Setting.get('accounting_payment_wallet_journal_code') || '',
        transfer: Setting.get('accounting_payment_transfer_journal_code') || '',
        check: Setting.get('accounting_payment_check_journal_code') || '',
        other: Setting.get('accounting_payment_other_journal_code') || ''
      }
    }
  end

  def payment_journal(payment_mean)
    @journal_codes[:payment][payment_mean]
  end

  def vat_journal
    @journal_codes[:vat]
  end

  def sales_journal(object_type)
    case object_type
    when 'WalletTransaction'
      @journal_codes[:wallet]
    else
      @journal_codes[:sales]
    end
  end
end

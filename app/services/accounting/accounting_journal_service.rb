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
      client: {
        card: Setting.get('accounting_card_client_journal_code') || '',
        wallet: Setting.get('accounting_wallet_client_journal_code') || '',
        other: Setting.get('accounting_other_client_journal_code') || ''
      }
    }
  end

  def client_journal(payment_mean)
    @journal_codes[:client][payment_mean]
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

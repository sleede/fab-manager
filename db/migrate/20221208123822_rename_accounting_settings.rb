# frozen_string_literal: true

# From this migration some settings related to accounting will be renamed.
# Eg. "accounting_journal_code" will be renamed to "accounting_sales_journal_code"
class RenameAccountingSettings < ActiveRecord::Migration[5.2]
  def up
    Setting.find_by(name: 'accounting_journal_code')&.update(name: 'accounting_sales_journal_code')
    Setting.find_by(name: 'accounting_card_client_code')&.update(name: 'accounting_payment_card_code')
    Setting.find_by(name: 'accounting_card_client_label')&.update(name: 'accounting_payment_card_label')
    Setting.find_by(name: 'accounting_wallet_client_code')&.update(name: 'accounting_payment_wallet_code')
    Setting.find_by(name: 'accounting_wallet_client_label')&.update(name: 'accounting_payment_wallet_label')
    Setting.find_by(name: 'accounting_other_client_code')&.update(name: 'accounting_payment_other_code')
    Setting.find_by(name: 'accounting_other_client_label')&.update(name: 'accounting_payment_other_label')
  end

  def down
    Setting.find_by(name: 'accounting_sales_journal_code')&.update(name: 'accounting_journal_code')
    Setting.find_by(name: 'accounting_payment_card_client_code')&.update(name: 'accounting_card_client_code')
    Setting.find_by(name: 'accounting_payment_card_client_label')&.update(name: 'accounting_card_client_label')
    Setting.find_by(name: 'accounting_payment_wallet_code')&.update(name: 'accounting_wallet_client_code')
    Setting.find_by(name: 'accounting_payment_wallet_label')&.update(name: 'accounting_wallet_client_label')
    Setting.find_by(name: 'accounting_payment_other_code')&.update(name: 'accounting_other_client_code')
    Setting.find_by(name: 'accounting_payment_other_label')&.update(name: 'accounting_other_client_label')
  end
end

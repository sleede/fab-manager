# frozen_string_literal: true

# From this migration the setting "accounting_journal_code" will be renamed to "accounting_sales_journal_code"
class RenameJournalCodeSetting < ActiveRecord::Migration[5.2]
  def up
    Setting.find_by(name: 'accounting_journal_code')&.update(name: 'accounting_sales_journal_code')
  end

  def down
    Setting.find_by(name: 'accounting_sales_journal_code')&.update(name: 'accounting_journal_code')
  end
end

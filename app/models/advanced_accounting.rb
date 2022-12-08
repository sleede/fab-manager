# frozen_string_literal: true

# AdvancedAccounting enables the various objects to have detailed accounting settings
class AdvancedAccounting < ApplicationRecord
  belongs_to :accountable, polymorphic: true
  belongs_to :machine, foreign_type: 'Machine', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :training, foreign_type: 'Training', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :space, foreign_type: 'Space', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :event, foreign_type: 'Event', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :product, foreign_type: 'Product', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :plan, foreign_type: 'Plan', foreign_key: 'accountable_id', inverse_of: :advanced_accounting

  after_save :rebuild_accounting_lines

  private

  def rebuild_accounting_lines
    invoices = case accountable_type
               when 'Machine', 'Training', 'Space', 'Event'
                 accountable.reservations.map(&:invoice_items).flatten.map(&:invoice).uniq
               when 'Product'
                 accountable.order_items.map(&:order).flatten.map(&:invoice).uniq
               when 'Plan'
                 accountable.subscriptions.map(&:invoice_items).flatten.map(&:invoice).uniq
               else
                 raise TypeError "Unknown accountable_type #{accountable_type}"
               end
    ids = invoices.map(&:id)
    AccountingWorker.perform_async(:invoices, ids)
  end
end

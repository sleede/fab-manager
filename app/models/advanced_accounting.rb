# frozen_string_literal: true

# AdvancedAccounting enables the various objects to have detailed accounting settings
class AdvancedAccounting < ApplicationRecord
  belongs_to :accountable, polymorphic: true
  belongs_to :machine, foreign_type: 'Machine', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :training, foreign_type: 'Training', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :space, foreign_type: 'Space', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
  belongs_to :event, foreign_type: 'event', foreign_key: 'accountable_id', inverse_of: :advanced_accounting
end

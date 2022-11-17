# frozen_string_literal: true

# Setting values, kept history of modifications
class HistoryValue < Footprintable
  belongs_to :setting
  belongs_to :invoicing_profile

  delegate :user, to: :invoicing_profile

  after_create :chain_record

  def sort_on_field
    'created_at'
  end
end

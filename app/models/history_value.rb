# frozen_string_literal: true

# Setting values, kept history of modifications
class HistoryValue < Footprintable
  belongs_to :setting
  belongs_to :invoicing_profile

  has_one :chained_element, as: :element, dependent: :restrict_with_exception
  delegate :footprint, to: :chained_element
  delegate :user, to: :invoicing_profile

  after_create :chain_record

  def sort_on_field
    'created_at'
  end
end

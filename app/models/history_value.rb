# frozen_string_literal: true

require 'checksum'

# Setting values, kept history of modifications
class HistoryValue < Footprintable
  belongs_to :setting
  belongs_to :invoicing_profile

  after_create :chain_record

  def chain_record
    super('created_at')
  end

  def user
    invoicing_profile.user
  end

  private

  def compute_footprint
    super('created_at')
  end
end

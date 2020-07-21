# frozen_string_literal: true

require 'checksum'

# Setting values, kept history of modifications
class HistoryValue < ApplicationRecord
  belongs_to :setting
  belongs_to :invoicing_profile

  after_create :chain_record

  def chain_record
    self.footprint = compute_footprint
    save!
    FootprintDebug.create!(
      footprint: footprint,
      data: FootprintService.footprint_data(HistoryValue, self, 'created_at'),
      klass: HistoryValue.name
    )
  end

  def check_footprint
    footprint == compute_footprint
  end

  def debug_footprint
    FootprintService.debug_footprint(HistoryValue, self)
  end

  def user
    invoicing_profile.user
  end

  private

  def compute_footprint
    FootprintService.compute_footprint(HistoryValue, self, 'created_at')
  end
end

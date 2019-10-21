# frozen_string_literal: true

require 'checksum'

# Setting values, kept history of modifications
class HistoryValue < ActiveRecord::Base
  belongs_to :setting
  belongs_to :invoicing_profile

  after_create :chain_record

  def chain_record
    self.footprint = compute_footprint
    save!
  end

  def check_footprint
    footprint == compute_footprint
  end

  def user
    invoicing_profile.user
  end

  private

  def compute_footprint
    FootprintService.compute_footprint(HistoryValue, self, 'created_at')
  end
end

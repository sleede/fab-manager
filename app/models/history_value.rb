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
    max_date = created_at || Time.current
    previous = HistoryValue.where('created_at < ?', max_date)
                           .order('created_at DESC')
                           .limit(1)

    columns = HistoryValue.columns.map(&:name)
                          .delete_if { |c| %w[footprint updated_at].include? c }

    Checksum.text("#{columns.map { |c| self[c] }.join}#{previous.first ? previous.first.footprint : ''}")
  end
end

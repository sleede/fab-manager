# frozen_string_literal: true

# Represents a due date and the associated amount for a PaymentSchedule
class PaymentScheduleItem < ApplicationRecord
  include Footprintable

  belongs_to :payment_schedule
  belongs_to :invoice
  after_create :chain_record

  def chain_record
    self.footprint = compute_footprint
    save!
    FootprintDebug.create!(
      footprint: footprint,
      data: FootprintService.footprint_data(PaymentScheduleItem, self),
      klass: PaymentScheduleItem.name
    )
  end

  def check_footprint
    footprint == compute_footprint
  end

  def compute_footprint
    FootprintService.compute_footprint(PaymentScheduleItem, self)
  end

  def self.columns_out_of_footprint
    %w[invoice_id]
  end
end

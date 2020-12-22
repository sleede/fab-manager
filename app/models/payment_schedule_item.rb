# frozen_string_literal: true

# Represents a due date and the associated amount for a PaymentSchedule
class PaymentScheduleItem < Footprintable
  belongs_to :payment_schedule
  belongs_to :invoice
  after_create :chain_record

  def self.columns_out_of_footprint
    %w[invoice_id]
  end
end

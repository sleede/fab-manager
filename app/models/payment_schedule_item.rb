# frozen_string_literal: true

# Represents a due date and the associated amount for a PaymentSchedule
class PaymentScheduleItem < ApplicationRecord
  belongs_to :payment_schedule
end

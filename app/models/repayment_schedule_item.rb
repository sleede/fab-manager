# frozen_string_literal: true

# Represents a due date and the associated amount for a RepaymentSchedule
class RepaymentScheduleItem < ApplicationRecord
  belongs_to :repayment_schedule
end

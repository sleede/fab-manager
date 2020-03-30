# frozen_string_literal: true

# TrainingsPricing configures the price of a Training session, per Group
class TrainingsPricing < ApplicationRecord
  belongs_to :training
  belongs_to :group

  def amount_by_plan(plan)
    amount
  end
end

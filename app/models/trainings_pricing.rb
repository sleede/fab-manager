class TrainingsPricing < ApplicationRecord
  belongs_to :training
  belongs_to :group

  def amount_by_plan(plan)
    amount
  end
end

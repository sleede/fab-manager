class MachinesPricing < ActiveRecord::Base
  belongs_to :machine
  belongs_to :group

  def amount_by_plan(plan)
    return not_subscribe_amount if plan.blank?
    plan = Plan.find(plan)
    if plan.interval == 'month'
      month_amount
    else
      year_amount
    end
  end
end

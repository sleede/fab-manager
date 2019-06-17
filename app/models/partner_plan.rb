# frozen_string_literal: true

# A special plan associated which can be associated with some users (with role 'partner')
# These partners will be notified when the subscribers to this plan are realizing some actions
class PartnerPlan < Plan
  resourcify

  before_create :assign_default_values

  def partners
    User.joins(:roles).where(roles: { name: 'partner', resource_type: 'PartnerPlan', resource_id: id })
  end

  private

  def assign_default_values
    assign_attributes(is_rolling: false)
  end
end

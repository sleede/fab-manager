# frozen_string_literal: true

# Provides methods for Plan & PartnerPlan actions
class PlansService
  class << self
    def create(type, partner, params)
      if params[:group_id] == 'all'
        plans = type.constantize.create_for_all_groups(params)
        return false unless plans

        plans.each { |plan| partner.add_role :partner, plan } unless partner.nil?
        { plan_ids: plans.map(&:id) }
      else
        plan = type.constantize.new(params)
        if plan.save
          partner&.add_role :partner, plan
        else
          return { errors: plan.errors.full_messages }
        end
        { plan_ids: [plan.id] }
      end
    rescue PaymentGatewayError => e
      { errors: e.message }
    end
  end
end

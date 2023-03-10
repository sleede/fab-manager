# frozen_string_literal: true

# API Controller for resources of type PlanLimitation
# PlanLimitation allows to restrict bookings of resources for the subscribers of that plan.
class API::PlanLimitationsController < API::ApiController
  def destroy
    @limitation = PlanLimitation.find(params[:id])
    authorize @limitation
    @limitation.destroy
    head :no_content
  end
end

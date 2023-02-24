# frozen_string_literal: true

# authorized 3rd party softwares can list the bookable machines through the OpenAPI
class OpenAPI::V1::BookableMachinesController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  expose_doc

  def index
    raise ActionController::ParameterMissing if params[:user_id].blank?

    @machines = Machine.all
    @machines = @machines.where(id: params[:machine_id]) if params[:machine_id].present?
    @machines = @machines.to_a

    user = User.find(params[:user_id])

    @machines.delete_if do |machine|
      (machine.trainings.count != 0) and !user.training_machine?(machine)
    end

    @hours_remaining = @machines.to_h { |m| [m.id, 0] }

    return unless user.subscription

    plan_id = user.subscription.plan_id
    @machines.each do |machine|
      credit = Credit.find_by(plan_id: plan_id, creditable: machine)
      users_credit = user.users_credits.find_by(credit: credit) if credit

      @hours_remaining[machine.id] = credit ? credit.hours - (users_credit.try(:hours_used) || 0) : 0
    end
  end
end

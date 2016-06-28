class OpenAPI::V1::BookableMachinesController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  def index
    raise ActionController::ParameterMissing if params[:user_id].blank?

    @machines = Machine.all

    @machines = @machines.where(id: params[:machine_id]) if params[:machine_id].present?

    @machines = @machines.to_a

    user = User.find(params[:user_id])

    @machines.delete_if do |machine|
      (machine.trainings.count != 0) and !user.is_training_machine?(machine)
    end


    @hours_remaining = Hash[@machines.map { |m| [m.id, 0] }]



    if user.subscription
      plan_id = user.subscription.plan_id

      @machines.each do |machine|
        credit = Credit.find_by(plan_id: plan_id, creditable: machine)
        users_credit = user.users_credits.find_by(credit: credit) if credit

        if credit
          @hours_remaining[machine.id] = credit.hours - (users_credit.try(:hours_used) || 0)
        else
          @hours_remaining[machine.id] = 0
        end
      end
    end
  end
end

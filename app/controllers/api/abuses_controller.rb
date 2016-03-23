class API::AbusesController < API::ApiController
  before_action :authenticate_user!, except: :create

  def index
    @groups = Group.all
  end

  def create
    @abuse = Abuse.new(abuse_params)
    if @abuse.save
      render status: :created
    else
      render json: @abuse.errors.full_messages, status: :unprocessable_entity
    end
  end

  private

  def abuse_params
    params.require(:abuse).permit(:signaled_type, :signaled_id, :first_name, :last_name, :email, :message)
  end
end

# frozen_string_literal: true

# API Controller for resources of type Abuse.
# Typical action is an user reporting an abuse on a project
class API::AbusesController < API::APIController
  before_action :authenticate_user!, except: :create
  before_action :set_abuse, only: %i[destroy]

  def index
    authorize Abuse
    @abuses = Abuse.all
  end

  def create
    @abuse = Abuse.new(abuse_params)
    if @abuse.save
      render status: :created
    else
      render json: @abuse.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Abuse
    @abuse.destroy
    head :no_content
  end

  private

  def set_abuse
    @abuse = Abuse.find(params[:id])
  end

  def abuse_params
    params.require(:abuse).permit(:signaled_type, :signaled_id, :first_name, :last_name, :email, :message)
  end
end

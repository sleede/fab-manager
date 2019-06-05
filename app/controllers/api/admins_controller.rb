# frozen_string_literal: true

# API Controller for resources of type User with role 'admin'.
class API::AdminsController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize :admin
    @admins = User.includes(profile: [:user_avatar]).admins
  end

  def create
    authorize :admin
    res = UserService.create_admin(admin_params)

    if res[:saved]
      @admin = res[:user]
      render :create, status: :created
    else
      render json: res[:user].errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    @admin = User.admins.find(params[:id])
    if current_user.admin? && @admin != current_user
      @admin.destroy
      head :no_content
    else
      head :unauthorized
    end
  end

  private

  def admin_params
    params.require(:admin).permit(
      :username, :email,
      profile_attributes: %i[first_name last_name phone],
      invoicing_profile_attributes: [address_attributes: [:address]],
      statistic_profile_attributes: %i[gender birthday]
    )
  end
end

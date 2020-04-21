# frozen_string_literal: true

# API Controller for resources of type Users with role :partner or :manager
class API::UsersController < API::ApiController
  before_action :authenticate_user!
  before_action :set_user, only: %i[destroy]

  def index
    if current_user.admin? && %w[partner manager].include?(params[:role])
      @users = User.with_role(params[:role].to_sym).includes(:profile)
    else
      head 403
    end
  end

  def create
    authorize User
    res = if params[:user]
            UserService.create_partner(partner_params)
          elsif params[:manager]
            UserService.create_manager(manager_params)
          else
            nil
          end

    if res[:saved]
      @user = res[:user]
      render status: :created
    else
      render json: res[:user].errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize User
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def partner_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end

  def manager_params
    params.require(:manager).permit(
        :username, :email, :group_id, :tag_ids,
        profile_attributes: %i[first_name last_name phone],
        invoicing_profile_attributes: [address_attributes: [:address]],
        statistic_profile_attributes: %i[gender birthday]
    )
  end
end

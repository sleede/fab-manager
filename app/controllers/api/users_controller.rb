# frozen_string_literal: true

# API Controller for resources of type Users with role :partner
class API::UsersController < API::ApiController
  before_action :authenticate_user!

  def index
    if current_user.admin? && params[:role] == 'partner'
      @users = User.with_role(:partner).includes(:profile)
    else
      head 403
    end
  end

  def create
    if current_user.admin?
      res = UserService.create_partner(partner_params)

      if res[:saved]
        @user = res[:user]
        render status: :created
      else
        render json: res[:user].errors.full_messages, status: :unprocessable_entity
      end
    else
      head 403
    end
  end

  private

  def partner_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end
end

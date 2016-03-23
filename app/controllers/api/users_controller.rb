class API::UsersController < API::ApiController
  before_action :authenticate_user!

  def index
    if current_user.is_admin? and params[:role] == 'partner'
      @users = User.with_role(:partner).includes(:profile)
    else
      head 403
    end
  end

  def create
    if current_user.is_admin?
      generated_password = Devise.friendly_token.first(8)
      @user = User.new(email: partner_params[:email], username: "#{partner_params[:first_name]}#{partner_params[:last_name]}",
                       password: generated_password, password_confirmation: generated_password, group_id: Group.first.id)
      @user.build_profile(first_name: partner_params[:first_name], last_name: partner_params[:last_name], gender: true, birthday: Time.now, phone: '0000000000')

      if @user.save
        @user.remove_role :member
        @user.add_role :partner
        render status: :created
      else
        render json: @user.errors.full_messages, status: :unprocessable_entity
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

class API::AdminsController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize :admin
    @admins = User.includes(profile: [:user_avatar]).admins
  end

  def create
    authorize :admin
    generated_password = Devise.friendly_token.first(8)
    @admin = User.new(admin_params.merge(password: generated_password))
    @admin.send :set_slug

    # we associate any random group to the admin as it is mandatory for users but useless for admins
    @admin.group = Group.first

    # if the authentication is made through an SSO, generate a migration token
    unless AuthProvider.active.providable_type == DatabaseProvider.name
      @admin.generate_auth_migration_token
    end

    if @admin.save(validate: false)
      @admin.send_confirmation_instructions
      @admin.add_role(:admin)
      @admin.remove_role(:member)
      UsersMailer.delay.notify_user_account_created(@admin, generated_password)
      render :create, status: :created
    else
      render json: @admin.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    @admin = User.admins.find(params[:id])
    if current_user.is_admin? and  @admin != current_user
      @admin.destroy
      head :no_content
    else
      head :unauthorized
    end
  end

  private

    def admin_params
      params.require(:admin).permit(:username, :email, profile_attributes: [:first_name, :last_name, :gender,
      :birthday, :phone, address_attributes: [:address]])
    end
end

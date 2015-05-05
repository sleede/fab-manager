class API::MembersController < API::ApiController
  before_action :authenticate_user!, except: [:last_subscribed]
  before_action :set_member, only: [:update]
  respond_to :json

  def index
    @members = policy_scope(User)
  end

  def last_subscribed
    @members = User.with_role(:member).includes(:profile).where('is_allow_contact = true AND confirmed_at IS NOT NULL').order('created_at desc').limit(params[:last])
    render :index
  end

  def show
    @member = User.friendly.find(params[:id])
    authorize @member
  end

  def create
    authorize User
    if !user_params[:password] and !user_params[:password_confirmation]
      generated_password = Devise.friendly_token.first(8)
      @member = User.new(user_params.merge(password: generated_password).permit!)
    else
      @member = User.new(user_params.permit!)
    end

    if @member.save
      @member.send_confirmation_instructions
      if !user_params[:password] and !user_params[:password_confirmation]
        UsersMailer.delay.notify_member_account_is_created(@member, generated_password)
      else
        UsersMailer.delay.notify_member_account_is_created(@member, user_params[:password])
      end
      render :show, status: :created, location: member_path(@member)
    else
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @member

    if @member.update(user_params.permit!)

      # Update password without logging out
      sign_in(@member, :bypass => true) unless current_user.is_admin?
      render :show, status: :ok, location: member_path(@member)
    else
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  def export_members
    authorize :export
    @datas = User.with_role(:member).includes(:group, :profile)
    respond_to do |format|
      format.html
      format.xls
    end
  end

  private
    def set_member
      @member = User.find(params[:id])
    end

    def user_params
      if current_user.id == params[:id].to_i
        params.require(:user).permit(:username, :email, :password, :password_confirmation, profile_attributes: [:id, :first_name, :last_name,
                                     :gender, :birthday, :phone, :interest, :software_mastered,
                                     :user_avatar_attributes => [:id, :attachment, :_destroy], :address_attributes => [:id, :address]])

      elsif current_user.is_admin?
        params.require(:user).permit!
      else
        params.require(:user)
      end
    end
end

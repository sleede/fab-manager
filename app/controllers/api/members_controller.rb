class API::MembersController < API::ApiController
  before_action :authenticate_user!, except: [:last_subscribed]
  before_action :set_member, only: [:update, :destroy, :merge]
  respond_to :json

  def index
    @requested_attributes = params[:requested_attributes]
    @query = policy_scope(User)

    unless params[:page].nil? and params[:size].nil?
      @query = @query.page(params[:page].to_i).per(params[:size].to_i)
    end

    # remove unmerged profiles from list
    @members = @query.to_a
    @members.delete_if { |u| u.need_completion? }
  end

  def last_subscribed
    @query = User.active.with_role(:member).includes(profile: [:user_avatar]).where('is_allow_contact = true AND confirmed_at IS NOT NULL').order('created_at desc').limit(params[:last])

    # remove unmerged profiles from list
    @members = @query.to_a
    @members.delete_if { |u| u.need_completion? }

    @requested_attributes = ['profile']
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


    # if the user is created by an admin and the authentication is made through an SSO, generate a migration token
    if current_user.is_admin? and AuthProvider.active.providable_type != DatabaseProvider.name
      @member.generate_auth_migration_token
    end

    if @member.save
      @member.generate_admin_invoice
      @member.send_confirmation_instructions
      if !user_params[:password] and !user_params[:password_confirmation]
        UsersMailer.delay.notify_user_account_created(@member, generated_password)
      else
        UsersMailer.delay.notify_user_account_created(@member, user_params[:password])
      end
      render :show, status: :created, location: member_path(@member)
    else
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @member
    @flow_worker = MembersProcessor.new(@member)

    if user_params[:group_id] and @member.group_id != user_params[:group_id].to_i and @member.subscribed_plan != nil
      # here a group change is requested but unprocessable, handle the exception
      @member.errors[:group_id] = t('members.unable_to_change_the_group_while_a_subscription_is_running')
      render json: @member.errors, status: :unprocessable_entity
    else
      # otherwise, run the user update
      if @flow_worker.update(user_params)
        # Update password without logging out
        sign_in(@member, :bypass => true) unless current_user.id != params[:id].to_i
        render :show, status: :ok, location: member_path(@member)
      else
        render json: @member.errors, status: :unprocessable_entity
      end
    end
  end

  def destroy
    authorize @member
    @member.soft_destroy
    sign_out(@member)
    head :no_content
  end

  # export subscriptions
  def export_subscriptions
    authorize :export

    export = Export.where({category:'users', export_type: 'subscriptions'}).where('created_at > ?', Subscription.maximum('updated_at')).last
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new({category:'users', export_type: 'subscriptions', user: current_user})
      if @export.save
        render json: {export_id: @export.id}, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file File.join(Rails.root, export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
    end
  end

  # export reservations
  def export_reservations
    authorize :export

    export = Export.where({category:'users', export_type: 'reservations'}).where('created_at > ?', Reservation.maximum('updated_at')).last
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new({category:'users', export_type: 'reservations', user: current_user})
      if @export.save
        render json: {export_id: @export.id}, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file File.join(Rails.root, export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
    end
  end

  def export_members
    authorize :export

    export = Export.where({category:'users', export_type: 'members'}).where('created_at > ?', User.with_role(:member).maximum('updated_at')).last
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new({category:'users', export_type: 'members', user: current_user})
      if @export.save
        render json: {export_id: @export.id}, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file File.join(Rails.root, export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
    end
  end

  def merge
    authorize @member

    # here the user query to be mapped to his already existing account

    token = params.require(:user).permit(:auth_token)[:auth_token]

    @account = User.find_by(auth_token: token)
    if @account
      @flow_worker = MembersProcessor.new(@account)
      begin
        if @flow_worker.merge_from_sso(@member)
          @member = @account
          # finally, log on the real account
          sign_in(@member, :bypass => true)
          render :show, status: :ok, location: member_path(@member)
        else
          render json: @member.errors, status: :unprocessable_entity
        end
      rescue DuplicateIndexError => error
        render json: {error: t('members.please_input_the_authentication_code_sent_to_the_address', EMAIL: error.message)}, status: :unprocessable_entity
      end
    else
      render json: {error: t('members.your_authentication_code_is_not_valid')}, status: :unprocessable_entity
    end
  end

  def list
    authorize User

    p = params.require(:query).permit(:search, :order_by, :page, :size)

    unless p[:page].is_a? Integer
      render json: {error: 'page must be an integer'}, status: :unprocessable_entity
    end

    unless p[:size].is_a? Integer
      render json: {error: 'size must be an integer'}, status: :unprocessable_entity
    end


    direction = (p[:order_by][0] == '-' ? 'DESC' : 'ASC')
    order_key = (p[:order_by][0] == '-' ? p[:order_by][1, p[:order_by].size] : p[:order_by])

    case order_key
      when 'last_name'
        order_key = 'profiles.last_name'
      when 'first_name'
        order_key = 'profiles.first_name'
      when 'email'
        order_key = 'users.email'
      when 'phone'
        order_key = 'profiles.phone'
      when 'group'
        order_key = 'groups.name'
      when 'plan'
        order_key = 'plans.base_name'
      else
        order_key = 'users.id'
    end

    @query = User.includes(:profile, :group, :subscriptions)
               .joins(:profile, :group, :roles, 'LEFT JOIN "subscriptions" ON "subscriptions"."user_id" = "users"."id"  LEFT JOIN "plans" ON "plans"."id" = "subscriptions"."plan_id"')
               .where("users.is_active = 'true' AND roles.name = 'member'")
               .order("#{order_key} #{direction}")
               .page(p[:page])
               .per(p[:size])

    # ILIKE => PostgreSQL case-insensitive LIKE
    @query = @query.where('profiles.first_name ILIKE :search OR profiles.last_name ILIKE :search OR profiles.phone ILIKE :search OR email ILIKE :search OR groups.name ILIKE :search OR plans.base_name ILIKE :search', search: "%#{p[:search]}%") if p[:search].size > 0

    @members = @query.to_a

  end

  def search
    @members = User.includes(:profile)
               .joins(:profile, :roles, 'LEFT JOIN "subscriptions" ON "subscriptions"."user_id" = "users"."id"')
               .where("users.is_active = 'true' AND roles.name = 'member'")
               .where("lower(f_unaccent(profiles.first_name)) ~ regexp_replace(:search, E'\\\\s+', '|') OR lower(f_unaccent(profiles.last_name)) ~ regexp_replace(:search, E'\\\\s+', '|')", search: params[:query].downcase)

    if current_user.is_member?
      # non-admin can only retrieve users with "public profiles"
      @members = @members.where("users.is_allow_contact = 'true'")
    else
      # only admins have the ability to filter by subscription
      if params[:subscription] === 'true'
        @members = @members.where('subscriptions.id IS NOT NULL AND subscriptions.expired_at >= :now', now: Date.today.to_s)
      elsif params[:subscription] === 'false'
        @members = @members.where('subscriptions.id IS NULL OR subscriptions.expired_at < :now',  now: Date.today.to_s)
      end
    end

    @members = @members.to_a
  end

  def mapping
    authorize User

    @members = User.includes(:profile)
  end

  private
    def set_member
      @member = User.find(params[:id])
    end

    def user_params
      if current_user.id == params[:id].to_i
        params.require(:user).permit(:username, :email, :password, :password_confirmation, :group_id, :is_allow_contact, :is_allow_newsletter,
                                      profile_attributes: [:id, :first_name, :last_name, :gender, :birthday, :phone, :interest, :software_mastered, :website, :job,
                                     :facebook, :twitter, :google_plus, :viadeo, :linkedin, :instagram, :youtube, :vimeo, :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr,
                                     user_avatar_attributes: [:id, :attachment, :_destroy], address_attributes: [:id, :address],
                                     organization_attributes: [:id, :name, address_attributes: [:id, :address]]])

      elsif current_user.is_admin?
        params.require(:user).permit(:username, :email, :password, :password_confirmation, :invoicing_disabled, :is_allow_contact, :is_allow_newsletter,
                                      :group_id, training_ids: [], tag_ids: [],
                                      profile_attributes: [:id, :first_name, :last_name, :gender, :birthday, :phone, :interest, :software_mastered, :website, :job,
                                      :facebook, :twitter, :google_plus, :viadeo, :linkedin, :instagram, :youtube, :vimeo, :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr,
                                      user_avatar_attributes: [:id, :attachment, :_destroy], address_attributes: [:id, :address],
                                      organization_attributes: [:id, :name, address_attributes: [:id, :address]]])

      end
    end
end

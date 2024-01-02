# frozen_string_literal: true

# API Controller for resources of type User with role 'member'
class API::MembersController < API::APIController
  before_action :authenticate_user!, except: [:last_subscribed]
  before_action :set_member, only: %i[update destroy merge complete_tour update_role validate]
  before_action :set_operator, only: %i[show update create merge validate]
  respond_to :json

  def index
    @requested_attributes = params[:requested_attributes]
    @query = policy_scope(User)

    @query = @query.page(params[:page].to_i).per(params[:size].to_i) unless params[:page].nil? && params[:size].nil?

    # remove unmerged profiles from list
    @members = @query.to_a
    @members.delete_if(&:need_completion?)
  end

  def last_subscribed
    @query, @members = Members::MembersService.last_registered(params[:last])

    @requested_attributes = ['profile']
    render :index
  end

  def show
    @member = User.friendly.find(params[:id])
    authorize @member
  end

  def create
    authorize :user, :create_member?

    @member = User.new(Members::MembersService.handle_organization(user_params.permit!))
    members_service = Members::MembersService.new(@member)

    if members_service.create(current_user, user_params)
      render :show, status: :created, location: member_path(@member)
    else
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @member
    members_service = Members::MembersService.new(@member)

    if members_service.update(user_params, current_user, params[:user][:current_password])
      # Update password without logging out
      bypass_sign_in(@member) unless current_user.id != params[:id].to_i
      render :show, status: :ok, location: member_path(@member)
    else
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @member
    @member.destroy
    sign_out(@member) if @member.id == current_user.id
    head :no_content
  end

  # export subscriptions
  def export_subscriptions
    authorize :export

    export = ExportService.last_export('users/subscriptions')
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new(category: 'users', export_type: 'subscriptions', user: current_user)
      if @export.save
        render json: { export_id: @export.id }, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file Rails.root.join(export.file),
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    end
  end

  # export reservations
  def export_reservations
    authorize :export

    export = ExportService.last_export('users/reservations')
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new(category: 'users', export_type: 'reservations', user: current_user)
      if @export.save
        render json: { export_id: @export.id }, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file Rails.root.join(export.file),
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    end
  end

  def export_members
    authorize :export

    export = ExportService.last_export('users/members')
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new(category: 'users', export_type: 'members', user: current_user)
      if @export.save
        render json: { export_id: @export.id }, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file Rails.root.join(export.file),
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    end
  end

  # the user is querying to be mapped to his already existing account
  def merge
    authorize @member

    token = token_param

    @account = User.find_by(auth_token: token)
    if @account
      members_service = Members::MembersService.new(@account)
      begin
        if members_service.merge_from_sso(@member)
          @member = @account
          # finally, log on the real account
          sign_in(@member, bypass: true)
          render :show, status: :ok, location: member_path(@member)
        else
          render json: @member.errors, status: :unprocessable_entity
        end
      rescue DuplicateIndexError => e
        render json: { error: t('members.please_input_the_authentication_code_sent_to_the_address', EMAIL: e.message) },
               status: :unprocessable_entity
      end
    else
      render json: { error: t('members.your_authentication_code_is_not_valid') }, status: :unprocessable_entity
    end
  end

  def list
    authorize User

    render json: { error: 'page must be an integer' }, status: :unprocessable_entity and return unless query_params[:page].is_a? Integer
    render json: { error: 'size must be an integer' }, status: :unprocessable_entity and return unless query_params[:size].is_a? Integer

    query = Members::ListService.list(query_params)
    @max_members = query.except(:offset, :limit, :order).count
    @members = query.to_a
  end

  def search
    @members = Members::ListService.search(current_user, params[:query], params[:subscription])
  end

  def mapping
    authorize User

    @members = User.includes(:profile)
  end

  def complete_tour
    authorize @member

    if Setting.get('feature_tour_display') == 'session'
      render json: { tours: [params[:tour]] }
    else
      tours = "#{@member.profile.tours} #{params[:tour]}"
      @member.profile.update(tours: tours.strip)

      render json: { tours: @member.profile.tours.split }
    end
  end

  def update_role
    authorize @member

    service = Members::MembersService.new(@member)
    service.update_role(params[:role], params[:group_id])

    render json: @member
  end

  def current
    @member = current_user
    authorize @member
    render json: @member
  end

  def validate
    authorize @member

    members_service = Members::MembersService.new(@member)

    uparams = params.require(:user).permit(:validated_at)
    if members_service.validate(uparams[:validated_at].present?)
      render :show, status: :ok, location: member_path(@member)
    else
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  private

  def set_member
    @member = User.find(params[:id])
  end

  def set_operator
    @operator = current_user
  end

  def user_params
    if current_user.id == params[:id].to_i
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :group_id, :is_allow_contact, :is_allow_newsletter,
                                   profile_attributes: [:id, :first_name, :last_name, :phone, :interest, :software_mastered, :website, :job,
                                                        :facebook, :twitter, :google_plus, :viadeo, :linkedin, :instagram, :youtube, :vimeo,
                                                        :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr,
                                                        { user_avatar_attributes: %i[id attachment destroy] }],
                                   invoicing_profile_attributes: [
                                     :id, :organization,
                                     {
                                       address_attributes: %i[id address],
                                       organization_attributes: [:id, :name, { address_attributes: %i[id address] }],
                                       user_profile_custom_fields_attributes: %i[id value invoicing_profile_id profile_custom_field_id]
                                     }
                                   ],
                                   statistic_profile_attributes: %i[id gender birthday])

    elsif current_user.privileged?
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :is_allow_contact, :is_allow_newsletter, :group_id,
                                   tag_ids: [],
                                   profile_attributes: [:id, :first_name, :last_name, :phone, :interest, :software_mastered, :website, :job,
                                                        :facebook, :twitter, :google_plus, :viadeo, :linkedin, :instagram, :youtube, :vimeo,
                                                        :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr, :note,
                                                        { user_avatar_attributes: %i[id attachment destroy] }],
                                   invoicing_profile_attributes: [
                                     :id, :organization, :external_id,
                                     {
                                       address_attributes: %i[id address],
                                       organization_attributes: [:id, :name, { address_attributes: %i[id address] }],
                                       user_profile_custom_fields_attributes: %i[id value invoicing_profile_id profile_custom_field_id]
                                     }
                                   ],
                                   statistic_profile_attributes: [:id, :gender, :birthday, { training_ids: [] }])

    end
  end

  def token_param
    params.require(:user).permit(:auth_token)[:auth_token]
  end

  def query_params
    params.require(:query).permit(:search, :filter, :order_by, :page, :size)
  end
end

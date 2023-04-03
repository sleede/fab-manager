# frozen_string_literal: true

# API Controller for resources of type ProfileCustomField
# ProfileCustomFields are fields configured by an admin, added to the user's profile
class API::ProfileCustomFieldsController < API::APIController
  before_action :authenticate_user!, except: :index
  before_action :set_profile_custom_field, only: %i[show update destroy]

  def index
    @profile_custom_fields = ProfileCustomField.all.order('id ASC')
    @profile_custom_fields = @profile_custom_fields.where(actived: params[:actived]) if params[:actived].present?
  end

  def show; end

  def create
    authorize ProfileCustomField
    @profile_custom_field = ProfileCustomField.new(profile_custom_field_params)
    if @profile_custom_field.save
      render status: :created
    else
      render json: @profile_custom_field.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @profile_custom_field

    if @profile_custom_field.update(profile_custom_field_params)
      render status: :ok
    else
      render json: @pack.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @profile_custom_field
    @profile_custom_field.destroy
    head :no_content
  end

  private

  def set_profile_custom_field
    @profile_custom_field = ProfileCustomField.find(params[:id])
  end

  def profile_custom_field_params
    params.require(:profile_custom_field).permit(:label, :required, :actived)
  end
end

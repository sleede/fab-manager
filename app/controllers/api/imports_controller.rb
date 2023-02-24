# frozen_string_literal: true

# API Controller for resources of type Import
class API::ImportsController < API::APIController
  before_action :authenticate_user!

  def show
    authorize Import

    @import = Import.find(params[:id])
  end

  def members
    authorize Import

    @import = Import.new(
      attachment: import_params,
      user: current_user,
      update_field: params[:update_field],
      category: 'members'
    )
    if @import.save
      render json: { id: @import.id }, status: :created
    else
      render json: @import.errors, status: :unprocessable_entity
    end
  end

  private

  def import_params
    params.require(:import_members)
  end
end

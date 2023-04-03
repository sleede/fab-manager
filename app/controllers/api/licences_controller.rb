# frozen_string_literal: true

# API Controller for resources of type Licence
# Licenses are used in Projects
class API::LicencesController < API::APIController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_licence, only: %i[show update destroy]

  def index
    @licences = Licence.all
  end

  def show; end

  def create
    authorize Licence
    @licence = Licence.new(licence_params)
    if @licence.save
      render :show, status: :created, location: @licence
    else
      render json: @licence.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Licence
    if @licence.update(licence_params)
      render :show, status: :ok, location: @licence
    else
      render json: @licence.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Licence
    @licence.destroy
    head :no_content
  end

  private

  def set_licence
    @licence = Licence.find(params[:id])
  end

  def licence_params
    params.require(:licence).permit(:name, :description)
  end
end

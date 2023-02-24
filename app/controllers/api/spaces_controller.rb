# frozen_string_literal: true

# API Controller for resources of type Space
class API::SpacesController < API::APIController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_space, only: %i[update destroy]
  respond_to :json

  def index
    @spaces = Space.includes(:space_image).where(deleted_at: nil)
  end

  def show
    @space = Space.includes(:space_files, :projects).friendly.find(params[:id])

    head :not_found if @space.deleted_at
  end

  def create
    authorize Space
    @space = Space.new(space_params)
    if @space.save
      render :show, status: :created, location: @space
    else
      render json: @space.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @space
    if @space.update(space_params)
      render :show, status: :ok, location: @space
    else
      render json: @space.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @space
    method = @space.destroyable? ? :destroy : :soft_destroy!
    @space.send(method)
    head :no_content
  end

  private

  def set_space
    @space = Space.friendly.find(params[:id])
  end

  def space_params
    params.require(:space).permit(:name, :description, :characteristics, :default_places, :disabled,
                                  space_image_attributes: %i[id attachment],
                                  space_files_attributes: %i[id attachment _destroy],
                                  advanced_accounting_attributes: %i[code analytical_section])
  end
end

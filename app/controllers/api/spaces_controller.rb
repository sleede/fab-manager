# frozen_string_literal: true

# API Controller for resources of type Space
class API::SpacesController < API::APIController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_space, only: %i[update destroy]
  respond_to :json

  def index
    @spaces = Space.includes(:space_image, :machines).where(deleted_at: nil)
    @spaces_indexed_with_parent = @spaces.index_with { |space| @spaces.find { |s| s.id == space.parent_id } }
    @spaces_grouped_by_parent_id = @spaces.group_by(&:parent_id)
  end

  def show
    @space = Space.includes(:space_files, :projects).friendly.find(params[:id])

    head :not_found if @space.deleted_at
  end

  def create
    authorize Space
    @space = Space.new(space_params)
    if @space.save
      update_space_children(@space, params[:space][:child_ids])
      render :show, status: :created, location: @space
    else
      render json: @space.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @space
    if @space.update(space_params)
      update_space_children(@space, params[:space][:child_ids])
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
                                  machine_ids: [],
                                  space_image_attributes: %i[id attachment],
                                  space_files_attributes: %i[id attachment _destroy],
                                  advanced_accounting_attributes: %i[code analytical_section])
  end

  def update_space_children(parent_space, child_ids)
    Space.transaction do
      parent_space.children.each { |child| child.update!(parent: nil) }
      child_ids.to_a.select(&:present?).each do |child_id|
        Space.find(child_id).update!(parent: parent_space)
      end
    end
  end
end

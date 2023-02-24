# frozen_string_literal: true

# API Controller for resources of type Group
# Groups are used for categorizing Users
class API::GroupsController < API::APIController
  before_action :authenticate_user!, except: :index

  def index
    @groups = GroupService.list(params)
  end

  def create
    authorize Group
    @group = Group.new(group_params)
    if @group.save
      render status: :created
    else
      render json: @group.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize Group
    @group = Group.find(params[:id])
    if @group.update(group_params)
      render status: :ok
    else
      render json: @group.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    @group = Group.find(params[:id])
    authorize @group
    @group.destroy
    head :no_content
  end

  private

  def group_params
    params.require(:group).permit(:name, :disabled)
  end
end

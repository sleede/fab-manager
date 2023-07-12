# frozen_string_literal: true

# API Controller for resources of type Child
# Children are used to provide a way to manage multiple users in the family account
class API::ChildrenController < API::APIController
  before_action :authenticate_user!
  before_action :set_child, only: %i[show update destroy validate]

  def index
    authorize Child
    user_id = current_user.id
    user_id = params[:user_id] if current_user.privileged? && params[:user_id]
    @children = Child.where(user_id: user_id).where('birthday >= ?', 18.years.ago).includes(:supporting_document_files).order(:created_at)
  end

  def show
    authorize @child
  end

  def create
    @child = Child.new(child_params)
    authorize @child
    if ChildService.create(@child)
      render status: :created
    else
      render json: @child.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @child

    if @child.update(child_params)
      render status: :ok
    else
      render json: @child.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @child
    @child.destroy
    head :no_content
  end

  def validate
    authorize @child

    cparams = params.require(:child).permit(:validated_at)
    if ChildService.validate(@child, cparams[:validated_at].present?)
      render :show, status: :ok, location: child_path(@child)
    else
      render json: @child.errors, status: :unprocessable_entity
    end
  end

  private

  def set_child
    @child = Child.find(params[:id])
  end

  def child_params
    params.require(:child).permit(:first_name, :last_name, :email, :phone, :birthday, :user_id,
                                  supporting_document_files_attributes: %i[id supportable_id supportable_type
                                                                           supporting_document_type_id
                                                                           attachment _destroy])
  end
end

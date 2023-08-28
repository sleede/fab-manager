# frozen_string_literal: true

# API Controller for resources of type ProjectCategory
class API::ProjectCategoriesController < ApplicationController
  before_action :set_project_category, only: %i[update destroy]
  before_action :authenticate_user!, only: %i[create update destroy]

  def index
    @project_categories = ProjectCategory.all
  end

  def create
    authorize ProjectCategory
    @project_category = ProjectCategory.new(project_category_params)
    if @project_category.save
      render json: @project_category, status: :created
    else
      render json: @project_category.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize ProjectCategory
    if @project_category.update(project_category_params)
      render json: @project_category, status: :ok
    else
      render json: @project_category.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize ProjectCategory
    @project_category.destroy
    head :no_content
  end

  private

  def set_project_category
    @project_category = ProjectCategory.find(params[:id])
  end

  def project_category_params
    params.require(:project_category).permit(:name)
  end
end

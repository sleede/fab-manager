# frozen_string_literal: true

# API Controller for resources of type Status
# Status are used to check Projects state
class API::StatusesController < ApplicationController
  before_action :set_status, only: %i[update destroy]
  before_action :authenticate_user!, only: %i[create update destroy]
  def index
    @statuses = Status.all
  end

  def create
    authorize Status
    @status = Status.new(status_params)
    if @status.save
      render json: @status, status: :created
    else
      render json: @status.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Status
    if @status.update(status_params)
      render json: @status, status: :ok
    else
      render json: @status.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Status
    @status.destroy
    head :no_content
  end

  private

  def set_status
    @status = Status.find(params[:id])
  end

  def status_params
    params.require(:status).permit(:label)
  end
end

# frozen_string_literal: true

# API Controller for resources of type OpenAPI::Client
# OpenAPI::Clients are used to allow access to the public API
class API::OpenAPIClientsController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize OpenAPI::Client
    @clients = OpenAPI::Client.order(:created_at)
  end

  def create
    @projets = OpenAPI::Client.new(client_params)
    authorize @projets
    if @projets.save
      render status: :created
    else
      render json: @projets.errors, status: :unprocessable_entity
    end
  end

  def update
    @projets = OpenAPI::Client.find(params[:id])
    authorize @projets
    if @projets.update(client_params)
      render status: :ok
    else
      render json: @projets.errors, status: :unprocessable_entity
    end
  end

  def reset_token
    @projets = OpenAPI::Client.find(params[:id])
    authorize @projets
    @projets.regenerate_token
  end

  def destroy
    @projets = OpenAPI::Client.find(params[:id])
    authorize @projets
    @projets.destroy
    head 204
  end

  private

  def client_params
    params.require(:open_api_client).permit(:name)
  end
end

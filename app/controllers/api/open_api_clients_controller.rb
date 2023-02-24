# frozen_string_literal: true

# API Controller for resources of type OpenAPI::Client
# OpenAPI::Clients are used to allow access to the public API
class API::OpenAPIClientsController < API::APIController
  before_action :authenticate_user!

  def index
    authorize OpenAPI::Client
    @clients = OpenAPI::Client.order(:created_at)
  end

  def create
    @client = OpenAPI::Client.new(client_params)
    authorize @client
    if @client.save
      render status: :created
    else
      render json: @client.errors, status: :unprocessable_entity
    end
  end

  def update
    @client = OpenAPI::Client.find(params[:id])
    authorize @client
    if @client.update(client_params)
      render status: :ok
    else
      render json: @client.errors, status: :unprocessable_entity
    end
  end

  def reset_token
    @client = OpenAPI::Client.find(params[:id])
    authorize @client
    @client.regenerate_token
  end

  def destroy
    @client = OpenAPI::Client.find(params[:id])
    authorize @client
    @client.destroy
    head :no_content
  end

  private

  def client_params
    params.require(:open_api_client).permit(:name)
  end
end

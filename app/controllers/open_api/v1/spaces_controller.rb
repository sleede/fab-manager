# frozen_string_literal: true

# authorized 3rd party softwares can fetch data about spaces through the OpenAPI
class OpenAPI::V1::SpacesController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  expose_doc

  before_action :set_space, only: %i[show]

  def index
    @spaces = Space.order(:created_at).where(deleted_at: nil)
  end

  def show; end

  private

  def set_space
    @space = Space.friendly.find(params[:id])
  end
end

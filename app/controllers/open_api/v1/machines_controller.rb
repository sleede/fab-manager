class OpenAPI::V1::MachinesController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  def index
    @machines = Machine.order(:created_at)
  end
end

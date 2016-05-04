class OpenAPI::V1::MachinesController < OpenAPI::V1::BaseController
  def index
    @machines = Machine.order(:created_at)
  end
end

class OpenAPI::V1::MachinesController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  def index
    @machines = Machine.order(:created_at)

    if params[:machine_id].present?
      @machines = @machines.where(id: params[:machine_id])
    end

  end
end

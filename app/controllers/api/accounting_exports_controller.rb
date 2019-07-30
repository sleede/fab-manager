# frozen_string_literal: true

# API Controller for exporting accounting data to external accounting softwares
class API::AccountingExportsController < API::ApiController

  before_action :authenticate_user!

  def export
    authorize :export

    export = Export.where(category: 'accounting', export_type: 'accounting-software')
                   .where('created_at > ?', Invoice.maximum('updated_at'))
                   .last
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new(
        category: 'accounting',
        export_type: 'accounting-software',
        user: current_user,
        extension: params[:extension],
        query: params[:query],
        key: params[:separator]
      )
      if @export.save
        render json: { export_id: @export.id }, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file File.join(Rails.root, export.file),
                type: 'text/csv',
                disposition: 'attachment'
    end
  end
end

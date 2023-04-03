# frozen_string_literal: true

# API Controller for resources of type Export
# Export are used to download data tables in offline files
class API::ExportsController < API::APIController
  before_action :authenticate_user!
  before_action :set_export, only: [:download]

  def download
    authorize @export
    mime_type = case @export.extension
                when 'xlsx'
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                when 'csv'
                  'text/csv'
                else
                  'application/octet-stream'
                end

    if FileTest.exist?(@export.file)
      send_file Rails.root.join(@export.file),
                type: mime_type,
                disposition: 'attachment'
    else
      render text: I18n.t('errors.messages.export_not_found'), status: :not_found
    end
  end

  def status
    authorize Export

    export = ExportService.last_export("#{params[:category]}/#{params[:type]}", params[:query], params[:key], params[:extension])

    if export.nil? || !FileTest.exist?(export.file)
      render json: { exists: false, id: nil }, status: :ok
    else
      render json: { exists: true, id: export.id }, status: :ok
    end
  end

  private

  def set_export
    @export = Export.find(params[:id])
  end
end

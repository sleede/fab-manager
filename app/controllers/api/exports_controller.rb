class API::ExportsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_export, only: [:download]

  def download
    authorize @export

    send_file File.join(Rails.root, @export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
  end

  def status
    authorize Export

    export = Export.where({category: params[:category], export_type: params[:type], query: params[:query], key: params[:key]}).last
    if export.nil? || !FileTest.exist?(export.file)
      render json: {exists: false, id: nil}, status: :ok
    else
      render json: {exists: true, id: export.id}, status: :ok
    end
  end

  private
  def set_export
    @export = Export.find(params[:id])
  end
end
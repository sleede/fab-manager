class API::ExportsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_export, only: [:download]

  def download
    authorize @export
    send_file File.join(Rails.root, @export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
  end

  private
  def set_export
    @export = Export.find(params[:id])
  end
end
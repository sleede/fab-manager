# frozen_string_literal: true

# API Controller for handling special actions on files
class API::FilesController < API::APIController
  before_action :authenticate_user!

  # test the mime type of the uploaded file
  def mime
    authorize :file

    content_type = Marcel::MimeType.for Pathname.new(file_params.path)
    render json: { type: content_type }
  end

  private

  def file_params
    params.require(:attachment)
  end
end

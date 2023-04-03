# frozen_string_literal: true

# API Controller for resources of type SupportingDocumentFile
# SupportingDocumentFiles are used in settings
class API::SupportingDocumentFilesController < API::APIController
  before_action :authenticate_user!
  before_action :set_supporting_document_file, only: %i[show update download]

  def index
    @supporting_document_files = SupportingDocumentFileService.list(current_user, params)
  end

  # PUT /api/supporting_document_files/1/
  def update
    authorize @supporting_document_file
    if SupportingDocumentFileService.update(@supporting_document_file, supporting_document_file_params)
      render :show, status: :ok, location: @supporting_document_file
    else
      render json: @supporting_document_file.errors, status: :unprocessable_entity
    end
  end

  # POST /api/supporting_document_files/
  def create
    @supporting_document_file = SupportingDocumentFile.new(supporting_document_file_params)
    authorize @supporting_document_file
    if SupportingDocumentFileService.create(@supporting_document_file)
      render :show, status: :created, location: @supporting_document_file
    else
      render json: @supporting_document_file.errors, status: :unprocessable_entity
    end
  end

  # GET /api/supporting_document_files/1/download
  def download
    authorize @supporting_document_file
    send_file @supporting_document_file.attachment.url, type: @supporting_document_file.attachment.content_type, disposition: 'attachment'
  end

  # GET /api/supporting_document_files/1/
  def show; end

  private

  def set_supporting_document_file
    @supporting_document_file = SupportingDocumentFile.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def supporting_document_file_params
    params.required(:supporting_document_file).permit(:supporting_document_type_id, :attachment, :user_id)
  end
end

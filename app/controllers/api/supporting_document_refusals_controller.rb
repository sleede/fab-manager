# frozen_string_literal: true

# API Controller for resources of type SupportingDocumentRefusal
# SupportingDocumentRefusal are used by admin refuse user's proof of identity file
class API::SupportingDocumentRefusalsController < API::APIController
  before_action :authenticate_user!

  def index
    authorize SupportingDocumentRefusal
    @supporting_document_refusals = SupportingDocumentRefusalService.list(params)
  end

  def show; end

  # POST /api/supporting_document_refusals/
  def create
    authorize SupportingDocumentRefusal
    @supporting_document_refusal = SupportingDocumentRefusal.new(supporting_document_refusal_params)
    if SupportingDocumentRefusalService.create(@supporting_document_refusal)
      render :show, status: :created, location: @supporting_document_refusal
    else
      render json: @supporting_document_refusal.errors, status: :unprocessable_entity
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def supporting_document_refusal_params
    params.required(:supporting_document_refusal).permit(:message, :operator_id, :user_id, supporting_document_type_ids: [])
  end
end

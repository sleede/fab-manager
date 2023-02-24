# frozen_string_literal: true

# API Controller for resources of type SupportingDocumentType
# ProofOfIdentityTypes are used to provide admin config proof of identity type by group
class API::SupportingDocumentTypesController < API::APIController
  before_action :authenticate_user!, except: :index
  before_action :set_supporting_document_type, only: %i[show update destroy]

  def index
    @supporting_document_types = SupportingDocumentTypeService.list(params)
  end

  def show; end

  def create
    authorize SupportingDocumentType
    @supporting_document_type = SupportingDocumentType.new(supporting_document_type_params)
    if @supporting_document_type.save
      render status: :created
    else
      render json: @supporting_document_type.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @supporting_document_type

    if @supporting_document_type.update(supporting_document_type_params)
      render status: :ok
    else
      render json: @supporting_document_type.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @supporting_document_type
    @supporting_document_type.destroy
    head :no_content
  end

  private

  def set_supporting_document_type
    @supporting_document_type = SupportingDocumentType.find(params[:id])
  end

  def supporting_document_type_params
    params.require(:supporting_document_type).permit(:name, group_ids: [])
  end
end

# frozen_string_literal: true

# API Controller for resources of type ProofOfIdentityType
# ProofOfIdentityTypes are used to provide admin config proof of identity type by group
class API::ProofOfIdentityTypesController < API::ApiController
  before_action :authenticate_user!, except: :index
  before_action :set_proof_of_identity_type, only: %i[show update destroy]

  def index
    @proof_of_identity_types = ProofOfIdentityTypeService.list(params)
  end

  def show; end

  def create
    authorize ProofOfIdentityType
    @proof_of_identity_type = ProofOfIdentityType.new(proof_of_identity_type_params)
    if @proof_of_identity_type.save
      render status: :created
    else
      render json: @proof_of_identity_type.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @proof_of_identity_type

    if @proof_of_identity_type.update(proof_of_identity_type_params)
      render status: :ok
    else
      render json: @pack.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @proof_of_identity_type
    @proof_of_identity_type.destroy
    head :no_content
  end

  private

  def set_proof_of_identity_type
    @proof_of_identity_type = ProofOfIdentityType.find(params[:id])
  end

  def proof_of_identity_type_params
    params.require(:proof_of_identity_type).permit(:name, group_ids: [])
  end
end

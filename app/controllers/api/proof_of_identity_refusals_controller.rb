# frozen_string_literal: true

# API Controller for resources of type ProofOfIdentityRefusal
# ProofOfIdentityRefusal are used by admin refuse user's proof of identity file
class API::ProofOfIdentityRefusalsController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize ProofOfIdentityRefusal
    @proof_of_identity_files = ProofOfIdentityRefusalService.list(params)
  end

  def show; end

  # POST /api/proof_of_identity_refusals/
  def create
    authorize ProofOfIdentityRefusal
    @proof_of_identity_refusal = ProofOfIdentityRefusal.new(proof_of_identity_refusal_params)
    if ProofOfIdentityRefusalService.create(@proof_of_identity_refusal)
      render :show, status: :created, location: @proof_of_identity_refusal
    else
      render json: @proof_of_identity_refusal.errors, status: :unprocessable_entity
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def proof_of_identity_refusal_params
    params.required(:proof_of_identity_refusal).permit(:message, :operator_id, :user_id, proof_of_identity_type_ids: [])
  end
end

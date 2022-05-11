# frozen_string_literal: true

# API Controller for resources of type ProofOfIdentityFile
# ProofOfIdentityFiles are used in settings
class API::ProofOfIdentityFilesController < API::ApiController
  before_action :authenticate_user!
  before_action :set_proof_of_identity_file, only: %i[show update download]

  def index
    @proof_of_identity_files = ProofOfIdentityFileService.list(current_user, params)
  end

  # PUT /api/proof_of_identity_files/1/
  def update
    authorize @proof_of_identity_file
    if ProofOfIdentityFileService.update(@proof_of_identity_file, proof_of_identity_file_params)
      render :show, status: :ok, location: @proof_of_identity_file
    else
      render json: @proof_of_identity_file.errors, status: :unprocessable_entity
    end
  end

  # POST /api/proof_of_identity_files/
  def create
    @proof_of_identity_file = ProofOfIdentityFile.new(proof_of_identity_file_params)
    authorize @proof_of_identity_file
    if ProofOfIdentityFileService.create(@proof_of_identity_file)
      render :show, status: :created, location: @proof_of_identity_file
    else
      render json: @proof_of_identity_file.errors, status: :unprocessable_entity
    end
  end

  # GET /api/proof_of_identity_files/1/download
  def download
    authorize @proof_of_identity_file
    send_file @proof_of_identity_file.attachment.url, type: @proof_of_identity_file.attachment.content_type, disposition: 'attachment'
  end

  # GET /api/proof_of_identity_files/1/
  def show; end

  private

  def set_proof_of_identity_file
    @proof_of_identity_file = ProofOfIdentityFile.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def proof_of_identity_file_params
    params.required(:proof_of_identity_file).permit(:proof_of_identity_type_id, :attachment, :user_id)
  end

end

# frozen_string_literal: true

require 'file_size_validator'

class ProofOfIdentityFile < ApplicationRecord
  mount_uploader :attachment, ProofOfIdentityFileUploader

  belongs_to :proof_of_identity_type
  belongs_to :user

  validates :attachment, file_size: { maximum: Rails.application.secrets.max_proof_of_identity_file_size&.to_i || 5.megabytes.to_i }
end

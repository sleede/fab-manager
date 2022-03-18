# frozen_string_literal: true

class ProofOfIdentityType < ApplicationRecord
  has_many :proof_of_identity_types_groups, dependent: :destroy
  has_many :groups, through: :proof_of_identity_types_groups

  has_many :proof_of_identity_files, dependent: :destroy
end

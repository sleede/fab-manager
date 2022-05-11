# frozen_string_literal: true

class ProofOfIdentityTypesGroup < ApplicationRecord
  belongs_to :proof_of_identity_type
  belongs_to :group
end

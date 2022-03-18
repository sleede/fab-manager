# frozen_string_literal: true

class ProofOfIdentityRefusal < ApplicationRecord
  belongs_to :user
  belongs_to :operator, class_name: 'User', foreign_key: :operator_id
  has_and_belongs_to_many :proof_of_identity_types
end

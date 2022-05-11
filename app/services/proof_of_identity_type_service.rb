# frozen_string_literal: true

# Provides methods for ProofOfIdentityType
class ProofOfIdentityTypeService
  def self.list(filters = {})
    types = []
    if filters[:group_id].present?
      group = Group.find(filters[:group_id])
      types = group.proof_of_identity_types.includes(:groups)
    else
      types = ProofOfIdentityType.all
    end
    types
  end
end

# frozen_string_literal: true

# Provides methods for ProofOfIdentityRefusal
class ProofOfIdentityRefusalService
  def self.list(filters = {})
    refusals = []
    if filters[:user_id].present?
      files = ProofOfIdentityRefusal.where(user_id: filters[:user_id])
    end
    refusals
  end

  def self.create(proof_of_identity_refusal)
    saved = proof_of_identity_refusal.save

    if saved
      NotificationCenter.call type: 'notify_admin_user_proof_of_identity_refusal',
                              receiver: User.admins_and_managers,
                              attached_object: proof_of_identity_refusal
      NotificationCenter.call type: 'notify_user_proof_of_identity_refusal',
                              receiver: proof_of_identity_refusal.user,
                              attached_object: proof_of_identity_refusal
    end
    saved
  end
end

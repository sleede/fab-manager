# frozen_string_literal: true

# Provides methods for ProofOfIdentityFile
class ProofOfIdentityFileService
  def self.list(operator, filters = {})
    files = []
    if filters[:user_id].present?
      if operator.privileged? || filters[:user_id].to_i == operator.id
        files = ProofOfIdentityFile.where(user_id: filters[:user_id])
      end
    end
    files
  end

  def self.create(proof_of_identity_file)
    saved = proof_of_identity_file.save

    if saved
      user = User.find(proof_of_identity_file.user_id)
      all_files_are_upload = true
      user.group.proof_of_identity_types.each do |type|
        file = type.proof_of_identity_files.find_by(user_id: proof_of_identity_file.user_id)
        unless file
          all_files_are_upload = false
        end
      end
      if all_files_are_upload
        NotificationCenter.call type: 'notify_admin_user_proof_of_identity_files_created',
                                receiver: User.admins_and_managers,
                                attached_object: user
      end
    end
    saved
  end

  def self.update(proof_of_identity_file, params)
    updated = proof_of_identity_file.update(params)
    if updated
      user = proof_of_identity_file.user
      all_files_are_upload = true
      user.group.proof_of_identity_types.each do |type|
        file = type.proof_of_identity_files.find_by(user_id: proof_of_identity_file.user_id)
        unless file
          all_files_are_upload = false
        end
      end
      if all_files_are_upload && !user.validated_at?
        NotificationCenter.call type: 'notify_admin_user_proof_of_identity_files_updated',
                                receiver: User.admins_and_managers,
                                attached_object: proof_of_identity_file
      end
    end
    updated
  end
end

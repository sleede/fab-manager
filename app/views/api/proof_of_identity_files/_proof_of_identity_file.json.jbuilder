# frozen_string_literal: true

json.extract! proof_of_identity_file, :id, :user_id, :proof_of_identity_type_id
json.attachment proof_of_identity_file.attachment.file.filename

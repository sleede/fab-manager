# frozen_string_literal: true

json.array! @proof_of_identity_files do |proof_of_identity_file|
  json.partial! 'api/proof_of_identity_files/proof_of_identity_file', proof_of_identity_file: proof_of_identity_file
end

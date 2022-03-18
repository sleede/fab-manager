# frozen_string_literal: true

json.array! @proof_of_identity_types do |proof_of_identity_type|
  json.partial! 'api/proof_of_identity_types/proof_of_identity_type', proof_of_identity_type: proof_of_identity_type
end

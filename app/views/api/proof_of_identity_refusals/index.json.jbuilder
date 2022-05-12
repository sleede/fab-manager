# frozen_string_literal: true

json.array! @proof_of_identity_refusals do |proof_of_identity_refusal|
  json.partial! 'api/proof_of_identity_refusals/proof_of_identity_refusal', proof_of_identity_refusal: proof_of_identity_refusal
end

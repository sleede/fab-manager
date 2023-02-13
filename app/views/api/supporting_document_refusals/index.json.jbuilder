# frozen_string_literal: true

json.array! @supporting_document_refusals do |supporting_document_refusal|
  json.partial! 'api/supporting_document_refusals/supporting_document_refusal', supporting_document_refusal: supporting_document_refusal
end

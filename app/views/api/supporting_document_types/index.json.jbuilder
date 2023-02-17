# frozen_string_literal: true

json.array! @supporting_document_types do |supporting_document_type|
  json.partial! 'api/supporting_document_types/supporting_document_type', supporting_document_type: supporting_document_type
end

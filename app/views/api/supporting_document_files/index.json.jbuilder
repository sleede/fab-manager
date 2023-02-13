# frozen_string_literal: true

json.array! @supporting_document_files do |supporting_document_file|
  json.partial! 'api/supporting_document_files/supporting_document_file', supporting_document_file: supporting_document_file
end

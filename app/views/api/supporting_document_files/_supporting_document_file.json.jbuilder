# frozen_string_literal: true

json.extract! supporting_document_file, :id, :user_id, :supporting_document_type_id
json.attachment supporting_document_file.attachment.file.filename

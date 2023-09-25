# frozen_string_literal: true

# add document_type to supporting_document_type
class AddDucumentTypeToSupportingDocumentType < ActiveRecord::Migration[7.0]
  def change
    add_column :supporting_document_types, :document_type, :string, default: 'User'
  end
end

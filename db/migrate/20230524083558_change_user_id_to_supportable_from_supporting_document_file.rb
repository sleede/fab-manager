# frozen_string_literal: true

# change user_id to supportable from supporting_document_file
class ChangeUserIdToSupportableFromSupportingDocumentFile < ActiveRecord::Migration[7.0]
  def change
    rename_column :supporting_document_files, :user_id, :supportable_id
    add_column :supporting_document_files, :supportable_type, :string, default: 'User'
  end
end

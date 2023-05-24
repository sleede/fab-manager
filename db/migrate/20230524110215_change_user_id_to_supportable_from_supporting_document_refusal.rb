# frozen_string_literal: true

# change user_id to supportable from supporting_document_refusal
class ChangeUserIdToSupportableFromSupportingDocumentRefusal < ActiveRecord::Migration[7.0]
  def change
    rename_column :supporting_document_refusals, :user_id, :supportable_id
    add_column :supporting_document_refusals, :supportable_type, :string, default: 'User'
  end
end

# frozen_string_literal: true

# From this migration we rename models from ProofOfIdentity* to SupportingDocument* which has more meaning
class RenameProofOfIdentityToSupportingDocument < ActiveRecord::Migration[5.2]
  def change
    rename_table :proof_of_identity_files, :supporting_document_files
    rename_table :proof_of_identity_refusals, :supporting_document_refusals
    rename_table :proof_of_identity_refusals_types, :supporting_document_refusals_types
    rename_table :proof_of_identity_types, :supporting_document_types
    rename_table :proof_of_identity_types_groups, :supporting_document_types_groups

    rename_column :supporting_document_files, :proof_of_identity_type_id, :supporting_document_type_id
    rename_column :supporting_document_refusals_types, :proof_of_identity_type_id, :supporting_document_type_id
    rename_column :supporting_document_refusals_types, :proof_of_identity_refusal_id, :supporting_document_refusal_id
    rename_column :supporting_document_types_groups, :proof_of_identity_type_id, :supporting_document_type_id
  end
end

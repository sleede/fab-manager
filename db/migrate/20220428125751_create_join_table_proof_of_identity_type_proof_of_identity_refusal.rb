class CreateJoinTableProofOfIdentityTypeProofOfIdentityRefusal < ActiveRecord::Migration[5.2]
  def change
    create_join_table :proof_of_identity_types, :proof_of_identity_refusals do |t|
      t.index [:proof_of_identity_type_id, :proof_of_identity_refusal_id], name: 'proof_of_identity_type_id_and_proof_of_identity_refusal_id'
      # t.index [:proof_of_identity_refusal_id, :proof_of_identity_type_id]
    end
  end
end

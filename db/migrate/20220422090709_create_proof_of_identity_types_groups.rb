class CreateProofOfIdentityTypesGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :proof_of_identity_types_groups do |t|
      t.references :proof_of_identity_type, foreign_key: true, index: { name: 'index_p_o_i_t_groups_on_proof_of_identity_type_id' }
      t.references :group, foreign_key: true, index: { name: 'index_p_o_i_t_groups_on_group_id' }

      t.timestamps
    end
  end
end

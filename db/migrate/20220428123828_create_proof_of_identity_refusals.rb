class CreateProofOfIdentityRefusals < ActiveRecord::Migration[5.2]
  def change
    create_table :proof_of_identity_refusals do |t|
      t.belongs_to :user, foreign_key: true
      t.integer :operator_id
      t.text :message

      t.timestamps
    end
  end
end

class CreateProofOfIdentityTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :proof_of_identity_types do |t|
      t.string :name

      t.timestamps
    end
  end
end

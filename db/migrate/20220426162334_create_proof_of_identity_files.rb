# frozen_string_literal: true

class CreateProofOfIdentityFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :proof_of_identity_files do |t|
      t.belongs_to :proof_of_identity_type, index: true
      t.belongs_to :user, index: true
      t.string :attachment

      t.timestamps
    end
  end
end

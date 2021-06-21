# frozen_string_literal: true

# Bought and consumed prepaid-packs
class CreateUserPrepaidPacks < ActiveRecord::Migration[5.2]
  def change
    create_table :user_prepaid_packs do |t|
      t.references :prepaid_pack, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :minutes_used, default: 0

      t.timestamps
    end
  end
end

# frozen_string_literal: true

# Bought and consumed prepaid-packs
class CreateStatisticProfilePrepaidPacks < ActiveRecord::Migration[5.2]
  def change
    create_table :statistic_profile_prepaid_packs do |t|
      t.references :prepaid_pack, foreign_key: true
      t.references :statistic_profile, foreign_key: true
      t.integer :minutes_used, default: 0
      t.datetime :expires_at

      t.timestamps
    end
  end
end

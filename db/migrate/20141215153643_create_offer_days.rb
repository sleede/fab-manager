# frozen_string_literal:true

class CreateOfferDays < ActiveRecord::Migration[4.2]
  def change
    create_table :offer_days do |t|
      t.belongs_to :subscription, index: true
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end
  end
end

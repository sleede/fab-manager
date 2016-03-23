class CreateOfferDays < ActiveRecord::Migration
  def change
    create_table :offer_days do |t|
      t.belongs_to :subscription, index: true
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end
  end
end

class CreateOrderActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :order_activities do |t|
      t.belongs_to :order, foreign_key: true
      t.references :operator_profile, foreign_key: { to_table: 'invoicing_profiles' }
      t.string :activity_type
      t.text :note

      t.timestamps
    end
  end
end

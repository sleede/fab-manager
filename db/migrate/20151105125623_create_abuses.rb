class CreateAbuses < ActiveRecord::Migration
  def change
    create_table :abuses do |t|
      t.references :signaled, polymorphic: true, index: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.text :message

      t.timestamps null: false
    end
  end
end

class CreateLicences < ActiveRecord::Migration
  def change
    create_table :licences do |t|
      t.string :name, null: false
      t.text :description
    end
  end
end

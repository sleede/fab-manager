class CreateStylesheets < ActiveRecord::Migration
  def change
    create_table :stylesheets do |t|
      t.text :contents

      t.timestamps null: false
    end
  end
end

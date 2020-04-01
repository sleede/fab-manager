# frozen_string_literal:true

class CreateCredits < ActiveRecord::Migration[4.2]
  def change
    create_table :credits do |t|
      t.references :creditable, polymorphic: true
      t.belongs_to :plan, index: true
      t.integer :hours

      t.timestamps
    end
  end
end

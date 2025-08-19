# frozen_string_literal: true

class CreateDoDocs < ActiveRecord::Migration[7.0]
  def change
    create_table :do_docs do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end

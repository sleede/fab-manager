# frozen_string_literal:true

class AddSlugToPlan < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :slug, :string
  end
end

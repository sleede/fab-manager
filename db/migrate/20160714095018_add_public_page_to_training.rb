# frozen_string_literal:true

class AddPublicPageToTraining < ActiveRecord::Migration[4.2]
  def change
    add_column :trainings, :public_page, :boolean, default: true
  end
end

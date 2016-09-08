class AddPublicPageToTraining < ActiveRecord::Migration
  def change
    add_column :trainings, :public_page, :boolean, default: true
  end
end

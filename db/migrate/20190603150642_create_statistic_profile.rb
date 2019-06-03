class CreateStatisticProfile < ActiveRecord::Migration
  def change
    create_table :statistic_profiles do |t|
      t.boolean :gender
      t.date :birthday
      t.belongs_to :group, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true
    end
  end
end

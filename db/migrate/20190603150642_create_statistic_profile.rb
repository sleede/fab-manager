class CreateStatisticProfile < ActiveRecord::Migration
  def change
    create_table :statistic_profiles do |t|
      t.boolean :gender
      t.date :birthday
      t.belongs_to :group, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :role, index: true, foreign_key: true
    end

    add_reference :reservations, :statistic_profile, index: true, foreign_key: true
    add_reference :subscriptions, :statistic_profile, index: true, foreign_key: true

    add_column :projects, :author_statistic_profile_id, :integer, index: true
    add_foreign_key :projects, :statistic_profiles, column: :author_statistic_profile_id
  end
end

class CreateStatisticProfileTrainings < ActiveRecord::Migration
  def change
    create_table :statistic_profile_trainings do |t|
      t.belongs_to :statistic_profile, index: true, foreign_key: true
      t.belongs_to :training, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

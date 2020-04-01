# frozen_string_literal:true

class CreateStatisticProfileTrainings < ActiveRecord::Migration[4.2]
  def change
    create_table :statistic_profile_trainings do |t|
      t.belongs_to :statistic_profile, index: true, foreign_key: true
      t.belongs_to :training, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

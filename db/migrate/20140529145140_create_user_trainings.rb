# frozen_string_literal:true

class CreateUserTrainings < ActiveRecord::Migration[4.2]
  def change
    create_table :user_trainings do |t|
      t.belongs_to :user, index: true
      t.belongs_to :machine, index: true

      t.timestamps
    end
  end
end

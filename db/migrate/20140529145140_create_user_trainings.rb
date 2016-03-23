class CreateUserTrainings < ActiveRecord::Migration
  def change
    create_table :user_trainings do |t|
      t.belongs_to :user, index: true
      t.belongs_to :machine, index: true

      t.timestamps
    end
  end
end

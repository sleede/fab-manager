class DeleteUserTrainings < ActiveRecord::Migration
  def change
    drop_table :user_trainings
  end
end

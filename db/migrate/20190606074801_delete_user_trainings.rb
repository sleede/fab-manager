# frozen_string_literal:true

class DeleteUserTrainings < ActiveRecord::Migration[4.2]
  def change
    drop_table :user_trainings
  end
end

# frozen_string_literal:true

class ChangeMachineIdToTrainingIdFromUserTraining < ActiveRecord::Migration[4.2]
  def change
    remove_belongs_to :user_trainings, :machine, index: true
    add_belongs_to :user_trainings, :training, index: true
  end
end

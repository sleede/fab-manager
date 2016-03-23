class ChangeMachineIdToTrainingIdFromUserTraining < ActiveRecord::Migration
  def change
    remove_belongs_to :user_trainings, :machine, index: true
    add_belongs_to :user_trainings, :training, index: true
  end
end

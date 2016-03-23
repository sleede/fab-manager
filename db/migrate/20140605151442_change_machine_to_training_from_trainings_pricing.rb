class ChangeMachineToTrainingFromTrainingsPricing < ActiveRecord::Migration
  def change
    remove_belongs_to :trainings_pricings, :machine, index: true
    add_belongs_to :trainings_pricings, :training, index: true
  end
end

# frozen_string_literal:true

class ChangeMachineToTrainingFromTrainingsPricing < ActiveRecord::Migration[4.2]
  def change
    remove_belongs_to :trainings_pricings, :machine, index: true
    add_belongs_to :trainings_pricings, :training, index: true
  end
end

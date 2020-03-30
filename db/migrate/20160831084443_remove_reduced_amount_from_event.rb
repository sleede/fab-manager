# frozen_string_literal:true

class RemoveReducedAmountFromEvent < ActiveRecord::Migration[4.2]
  def change
    remove_column :events, :reduced_amount, :integer
  end
end

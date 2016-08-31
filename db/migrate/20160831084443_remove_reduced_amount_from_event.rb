class RemoveReducedAmountFromEvent < ActiveRecord::Migration
  def change
    remove_column :events, :reduced_amount, :integer
  end
end

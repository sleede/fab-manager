# frozen_string_literal:true

class AddTrainingCreditNbToPlan < ActiveRecord::Migration[4.2]
  def change
    add_column :plans, :training_credit_nb, :integer

    if Plan.column_names.include? "training_credit_nb"
      Plan.all.each do |p|
        p.update_columns(training_credit_nb: (p.interval == 'month' ? 1 : 5))
      end
    end
  end
end

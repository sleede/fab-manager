class AddDefaultForTrainingNbCreditToPlans < ActiveRecord::Migration
  def up
    change_column_default :plans, :training_credit_nb, 0

    execute <<-SQL
      UPDATE plans SET training_credit_nb = 0 WHERE training_credit_nb is NULL;
    SQL
  end

  def down
    change_column_default :plans, :training_credit_nb, nil

    execute <<-SQL
      UPDATE plans SET training_credit_nb = NULL WHERE training_credit_nb = 0;
    SQL
  end
end

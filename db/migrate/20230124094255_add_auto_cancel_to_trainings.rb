# frozen_string_literal: true

# From this migration, we allows auto-cancellation of trainings
# if a minimum number of user are not registred, X hours before the
# beginning of the training
class AddAutoCancelToTrainings < ActiveRecord::Migration[5.2]
  def change
    change_table :trainings, bulk: true do |t|
      t.boolean :auto_cancel, default: false
      t.integer :auto_cancel_threshold
      t.integer :auto_cancel_deadline
    end
  end
end

# frozen_string_literal: true

# From this migration we remove is_rolling:true as the default value, because this introduced a bug:
# if the user leaves the form empty, the plan is considered as rolling which is not the desired behavior
class ChangeDefaultForPlanIsRolling < ActiveRecord::Migration[5.2]
  def change
    change_column_default :plans, :is_rolling, from: true, to: nil
  end
end

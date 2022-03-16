# frozen_string_literal: true

# This migration removes the NotNull constraint on the foreign key of closed_by
# column on the accounting_periods table. This is needed because it prevented
# to delete an admin who closed an accounting period.
class AllowUpdateClosedByOnAccountingPeriods < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      CREATE OR REPLACE RULE accounting_periods_upd_protect AS ON UPDATE
      TO accounting_periods
      WHERE (
        new.start_at <> old.start_at OR
        new.end_at <> old.end_at OR
        new.closed_at <> old.closed_at OR 
        new.period_total <> old.period_total OR
        new.perpetual_total <> old.perpetual_total)
      DO INSTEAD NOTHING;
    SQL
  end

  def down
    execute <<~SQL
      CREATE OR REPLACE RULE accounting_periods_upd_protect AS ON UPDATE
      TO accounting_periods DO INSTEAD NOTHING;
    SQL
  end
end

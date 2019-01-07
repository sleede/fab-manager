class ProtectAccountingPeriods < ActiveRecord::Migration

  # PostgreSQL only
  def up
    execute("CREATE RULE accounting_periods_del_protect AS ON DELETE TO #{AccountingPeriod.arel_table.name} DO INSTEAD NOTHING;")
    execute("CREATE RULE accounting_periods_upd_protect AS ON UPDATE TO #{AccountingPeriod.arel_table.name} DO INSTEAD NOTHING;")
  end

  def down
    execute("DROP RULE IF EXISTS accounting_periods_del_protect ON #{AccountingPeriod.arel_table.name};")
    execute("DROP RULE IF EXISTS accounting_periods_upd_protect ON #{AccountingPeriod.arel_table.name};")
  end
end

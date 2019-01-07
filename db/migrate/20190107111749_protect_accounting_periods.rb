class ProtectAccountingPeriods < ActiveRecord::Migration

  # PostgreSQL only
  def up
    execute('CREATE RULE accounting_periods_del_protect AS ON DELETE TO accounting_periods DO INSTEAD NOTHING;')
    execute('CREATE RULE accounting_periods_upd_protect AS ON UPDATE TO accounting_periods DO INSTEAD NOTHING;')
  end

  def down
    execute('DROP RULE IF EXISTS accounting_periods_del_protect ON accounting_periods;')
    execute('DROP RULE IF EXISTS accounting_periods_upd_protect ON accounting_periods;')
  end
end

# frozen_string_literal:true

class MigrateSettingsValueToHistoryValues < ActiveRecord::Migration[4.2]
  def up
    user = User.admins.first
    Setting.all.each do |setting|
      hv = HistoryValue.new(
        setting: setting,
        user: user,
        value: setting['value']
      )
      hv.save!
    end
  end

  def down
    # PostgreSQL only (distinct on)
    values = execute("SELECT DISTINCT ON (setting_id) setting_id, value, created_at
                          FROM #{HistoryValue.arel_table.name}
                          ORDER BY setting_id, created_at DESC, value")
    values.each do |val|
      value = val['value'] ? val['value'].tr("'", '"') : ''
      execute("UPDATE settings
                   SET value = '#{value}'
                   WHERE id = #{val['setting_id']}")
    end
  end
end

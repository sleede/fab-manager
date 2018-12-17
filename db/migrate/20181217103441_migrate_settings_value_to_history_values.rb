class MigrateSettingsValueToHistoryValues < ActiveRecord::Migration
  def up
    user = User.admins.first
    Setting.all.each do |setting|
      HistoryValue.create!(
        setting: setting,
        user: user,
        value: setting.value
      )
    end
  end

  def down
    # PostgreSQL only
    values = execute("SELECT DISTINCT ON (setting_id) setting_id, value, created_at
                          FROM #{HistoryValue.arel_table.name}
                          ORDER BY setting_id, created_at DESC, value")
    values.each do |val|
      Setting.find(val['setting_id']).update_attributes(value: val['value'])
    end
  end
end

json.setting do
  json.partial! 'api/settings/setting', setting: @setting
  if @show_history
    json.history @setting.history_values do |value|
      json.extract! value, :value, :created_at
      json.user do
        json.id value.user_id
        json.name "#{value.user.first_name} #{value.user.last_name}"
      end
    end
  end
end

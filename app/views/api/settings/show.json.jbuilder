json.setting do
  json.partial! 'api/settings/setting', setting: @setting
  if @show_history
    json.history @setting.history_values do |value|
      json.extract! value, :id, :value, :created_at
      unless value.invoicing_profile.nil?
        json.user do
          json.id value.invoicing_profile.user_id
          json.name value.invoicing_profile.full_name
        end
      end
    end
  end
end

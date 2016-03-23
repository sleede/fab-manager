@settings.each do |setting|
  json.set! setting.name, setting.value
end

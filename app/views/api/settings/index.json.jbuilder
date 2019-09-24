# frozen_string_literal: true

@settings.each do |setting|
  json.set! setting.name, setting.value
end

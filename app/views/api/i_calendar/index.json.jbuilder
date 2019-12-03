# frozen_string_literal: true

json.array!(@i_cals) do |i_cal|
  json.partial! 'api/i_calendar/i_calendar', i_cal: i_cal
end

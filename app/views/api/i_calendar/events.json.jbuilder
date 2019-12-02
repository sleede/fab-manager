# frozen_string_literal: true

json.array!(@events) do |event|
  json.id event.uid
  json.title event.i_calendar.text_hidden ? '' : event.summary
  json.start event.dtstart.iso8601
  json.end event.dtend.iso8601
  json.backgroundColor 'white'
end

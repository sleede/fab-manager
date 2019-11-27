# frozen_string_literal: true

json.array!(@events) do |event|
  json.id event[:event].uid
  json.title event[:calendar].text_hidden ? '' : event[:event].summary
  json.start event[:event].dtstart.iso8601
  json.end event[:event].dtend.iso8601
  json.backgroundColor 'white'
end

# frozen_string_literal: true

json.array!(@reservations) do |r|
  json.partial! 'api/reservations/reservation', reservation: r
end

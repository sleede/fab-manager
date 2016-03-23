json.array!(@reservations) do |r|
  json.partial! 'api/reservations/reservation', reservation: r
  json.url reservation_url(r, format: :json)
end

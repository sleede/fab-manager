user_is_admin = (current_user and current_user.admin?)

json.array!(@reservation_contexts) do |reservation_context|
  json.extract! reservation_context, :id, :name, :applicable_on
  json.related_to reservation_context.reservations.count if user_is_admin
end

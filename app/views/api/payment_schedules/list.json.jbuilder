# frozen_string_literal: true

max_schedules = @payment_schedules.except(:offset, :limit, :order).count

json.array! @payment_schedules do |ps|
  json.max_length max_schedules
  json.partial! 'api/payment_schedules/payment_schedule', payment_schedule: ps
end

# frozen_string_literal: true

# PlansAvailability is the relation table between a Plan and an Availability.
# An Availability which is associated with a Plan can only be booked by members having subscribed to this Plan.
class PlansAvailability < ApplicationRecord
  belongs_to :plan
  belongs_to :availability
end

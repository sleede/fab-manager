# frozen_string_literal: true

class PlansAvailability < ApplicationRecord
  belongs_to :plan
  belongs_to :availability
end

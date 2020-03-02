# frozen_string_literal: true

class PlansAvailability < ActiveRecord::Base
  belongs_to :plan
  belongs_to :availability
end

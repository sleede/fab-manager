# frozen_string_literal: true

# MachinesAvailability is the relation table between a Machine and a Product.
class MachinesProduct < ApplicationRecord
  belongs_to :machine
  belongs_to :product
end

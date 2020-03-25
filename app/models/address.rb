# frozen_string_literal: true

# Address is a database record that can be placed on a map.
class Address < ApplicationRecord
  belongs_to :placeable, polymorphic: true
end

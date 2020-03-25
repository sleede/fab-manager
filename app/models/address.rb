class Address < ApplicationRecord
  belongs_to :placeable, polymorphic: true
end

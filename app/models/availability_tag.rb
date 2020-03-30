# frozen_string_literal: true

# Abuse is a relation table between Availability and Tag.
# Associating a Tag to an Availability restrict it for reservation to users with the same Tag.
class AvailabilityTag < ApplicationRecord
  belongs_to :availability
  belongs_to :tag
end

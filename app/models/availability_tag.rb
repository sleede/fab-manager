class AvailabilityTag < ActiveRecord::Base
  belongs_to :availability
  belongs_to :tag
end

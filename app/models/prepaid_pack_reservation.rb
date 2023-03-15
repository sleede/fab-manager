# frozen_string_literal: true

# Save the association between a Reservation and a PrepaidPack to keep the usage history.
class PrepaidPackReservation < ApplicationRecord
  belongs_to :statistic_profile_prepaid_pack
  belongs_to :reservation
end

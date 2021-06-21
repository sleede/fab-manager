# frozen_string_literal: true

# Associate a customer with a bought prepaid-packs of hours for machines/spaces.
# Also saves the amount of hours used
class StatisticProfilePrepaidPack < ApplicationRecord
  belongs_to :prepaid_pack
  belongs_to :statistic_profile
end

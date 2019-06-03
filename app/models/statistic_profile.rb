class StatisticProfile < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  # relations to reservations, trainings, subscriptions
end

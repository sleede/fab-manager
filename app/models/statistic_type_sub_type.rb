class StatisticTypeSubType < ActiveRecord::Base
  belongs_to :statistic_type
  belongs_to :statistic_sub_type
end

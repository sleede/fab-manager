class StatisticField < ApplicationRecord
  include LabelI18nConcern

  has_one :statistic_index
end

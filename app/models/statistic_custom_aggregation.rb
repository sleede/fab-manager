# frozen_string_literal: true

# StatisticCustomAggregation is an ElasticSearch aggregation that will run when the end-user is browsing the statistics
# page for the related statisticType.
# See https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
class StatisticCustomAggregation < ApplicationRecord
  belongs_to :statistic_type
end

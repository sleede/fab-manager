# https://github.com/ruckus/active-record-query-trace
# traces the origin of active record queries, useful for optimisation purposes
if Rails.env.development?
  ActiveRecordQueryTrace.enabled = false  # set to true to enable
  ActiveRecordQueryTrace.level = :app
end

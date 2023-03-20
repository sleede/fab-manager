# frozen_string_literal: true

# Helpers for database operations
module DbHelper
  # Ruby times are localised and does not have the same precision as database times do comparing them in .where() clauses may
  # result in unexpected results. This function worksaround this issue by converting the Time to a database-comparable format
  # @param [Time]
  # @return [String]
  def db_time(time)
    time.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')
  end
end

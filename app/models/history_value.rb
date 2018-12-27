class HistoryValue < ActiveRecord::Base
  belongs_to :setting
  belongs_to :user
end

class Category < ActiveRecord::Base
  has_and_belongs_to_many :events, join_table: :events_categories
end

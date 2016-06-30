class Category < ActiveRecord::Base
  has_and_belongs_to_many :events, join_table: :events_categories, dependent: :destroy

  def safe_destroy
    if count > 1
      destroy
    else
      false
    end
  end
end

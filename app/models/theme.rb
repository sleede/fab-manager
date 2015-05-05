class Theme < ActiveRecord::Base
  has_and_belongs_to_many :projects, join_table: :projects_themes
  validates :name, presence: true, length: { maximum: 80 }
end
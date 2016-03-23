class Component < ActiveRecord::Base
  has_and_belongs_to_many :projects, join_table: :projects_components
  validates :name, presence: true, length: { maximum: 50 }
end
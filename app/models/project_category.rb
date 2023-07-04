class ProjectCategory < ApplicationRecord
  validates :name, presence: true

  has_many :projects_project_categories, dependent: :destroy
  has_many :projects, through: :projects_project_categories
end

class ProjectsProjectCategory < ApplicationRecord
  belongs_to :project
  belongs_to :project_category
end

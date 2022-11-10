# frozen_string_literal: true

# ProjectsSpace is the relation table between a Project and a Space
# => spaces used in a project
class ProjectsSpace < ApplicationRecord
  belongs_to :space
  belongs_to :project
end

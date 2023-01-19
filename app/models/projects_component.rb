# frozen_string_literal: true

# ProjectsComponent is the relation table between a Component and a Project.
class ProjectsComponent < ApplicationRecord
  belongs_to :component
  belongs_to :project
end

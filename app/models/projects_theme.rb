# frozen_string_literal: true

# ProjectsTheme is the relation table between a Theme and a Project.
class ProjectsTheme < ApplicationRecord
  belongs_to :theme
  belongs_to :project
end

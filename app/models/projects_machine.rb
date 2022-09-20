# frozen_string_literal: true

# ProjectsMachine is the relation table between a Machine and a Project.
class ProjectsMachine < ApplicationRecord
  belongs_to :machine
  belongs_to :project
end

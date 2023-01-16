# frozen_string_literal: true

# Here we link status to their projects
class ProjectStatus < ApplicationRecord
  belongs_to :project
  belongs_to :status
end

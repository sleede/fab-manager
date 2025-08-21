# frozen_string_literal: true

# DoDoc is a model representing DoDoc api name and url
class DoDoc < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true

  # Clear DoDoc projects cache when DoDoc changes
  after_save :invalidate_projects_cache
  after_destroy :invalidate_projects_cache

  private

  def invalidate_projects_cache
    DoDocProjectsService.invalidate_cache
  end
end

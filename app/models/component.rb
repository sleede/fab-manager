# frozen_string_literal: true

# Component is a material that can be used in Projects.
class Component < ApplicationRecord
  has_many :projects_components, dependent: :destroy
  has_many :projects, through: :projects_components
  validates :name, presence: true, length: { maximum: 50 }
end

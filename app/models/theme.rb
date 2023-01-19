# frozen_string_literal: true

# Theme is an optional filter used to categorize Projects
class Theme < ApplicationRecord
  has_many :projects_themes, dependent: :destroy
  has_many :projects, through: :projects_themes
  validates :name, presence: true, length: { maximum: 80 }
end

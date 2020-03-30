# frozen_string_literal: true

# Theme is an optional filter used to categorize Projects
class Theme < ApplicationRecord
  has_and_belongs_to_many :projects, join_table: :projects_themes
  validates :name, presence: true, length: { maximum: 80 }
end
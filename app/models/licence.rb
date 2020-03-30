# frozen_string_literal: true

# Licence is an agreement about intellectual property that can be used in Projects.
class Licence < ApplicationRecord

  has_many :projects
  validates :name, presence: true, length: { maximum: 160 }
end
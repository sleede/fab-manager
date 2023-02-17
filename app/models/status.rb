# frozen_string_literal: true

# Set statuses for projects (new, pending, done...)
class Status < ApplicationRecord
  validates :name, presence: true
  has_many :projects, dependent: :nullify
end

# frozen_string_literal: true

# Set statuses for projects (new, pending, done...)
class Status < ApplicationRecord
  validates :label, presence: true
  has_many :projects, dependent: :nullify
end

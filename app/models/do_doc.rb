# frozen_string_literal: true

# DoDoc is a model representing DoDoc api name and url
class DoDoc < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true
end

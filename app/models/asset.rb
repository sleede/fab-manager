# frozen_string_literal: true

require 'file_size_validator'

# Generic class, parent of uploadable items
class Asset < ApplicationRecord
  belongs_to :viewable, polymorphic: true
end

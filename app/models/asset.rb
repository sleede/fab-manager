require 'file_size_validator'

class Asset < ActiveRecord::Base
  belongs_to :viewable, polymorphic: true
end

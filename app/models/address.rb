class Address < ActiveRecord::Base
  belongs_to :placeable, polymorphic: true
end

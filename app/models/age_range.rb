class AgeRange < ActiveRecord::Base
  has_many :events, dependent: :nullify
end

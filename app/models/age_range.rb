class AgeRange < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :events, dependent: :nullify
end

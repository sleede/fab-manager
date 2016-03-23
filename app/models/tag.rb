class Tag < ActiveRecord::Base
  has_many :user_tags, dependent: :destroy
  has_many :users, through: :user_tags

  has_many :availability_tags, dependent: :destroy
  has_many :availabilities, through: :availability_tags
end

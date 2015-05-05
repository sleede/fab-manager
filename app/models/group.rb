class Group < ActiveRecord::Base
  has_many :plans

  has_many :trainings_pricings, dependent: :destroy

  has_many :machines_pricings, dependent: :destroy
end

class Licence < ApplicationRecord

  has_many :projects
  validates :name, presence: true, length: { maximum: 160 }
end
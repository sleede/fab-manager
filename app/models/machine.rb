class Machine < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  has_one :machine_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :machine_image, allow_destroy: true

  has_many :machine_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :machine_files, allow_destroy: true

  has_and_belongs_to_many :projects, join_table: 'projects_machines'

  validates :name, presence: true, length: { maximum: 50 }
  validates :description, presence: true

end

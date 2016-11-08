class ProjectStep < ActiveRecord::Base
  belongs_to :project
  has_many :project_step_images, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :project_step_images, allow_destroy: true, reject_if: :all_blank
end

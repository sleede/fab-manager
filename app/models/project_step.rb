class ProjectStep < ActiveRecord::Base
  belongs_to :project
  has_one :project_step_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :project_step_image, allow_destroy: true
end

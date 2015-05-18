class Project < ActiveRecord::Base
  include AASM
  include NotifyWith::NotificationAttachedObject

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :project_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :project_image, allow_destroy: true
  has_many :project_caos, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :project_caos, allow_destroy: true, reject_if: :all_blank

  has_and_belongs_to_many :machines, join_table: :projects_machines
  has_and_belongs_to_many :components, join_table: :projects_components
  has_and_belongs_to_many :themes, join_table: :projects_themes

  has_many :project_users, dependent: :destroy
  has_many :users, through: :project_users

  belongs_to :author, foreign_key: :author_id, class_name: 'User'
  belongs_to :licence, foreign_key: :licence_id

  has_many :project_steps, dependent: :destroy
  accepts_nested_attributes_for :project_steps, allow_destroy: true

  after_save :after_save_and_publish

  aasm :column => 'state' do
    state :draft, initial: true
    state :published

    event :publish, :after => :notify_admin_when_project_published do
      transitions from: :draft, :to => :published
    end
  end

  #scopes
  scope :published, -> { where("state = 'published'") }

  private
  def notify_admin_when_project_published
    NotificationCenter.call type: 'notify_admin_when_project_published',
                            receiver: User.admins,
                            attached_object: self
  end

  def after_save_and_publish
    if state_changed? and published?
      update_columns(published_at: Time.now)
      notify_admin_when_project_published
    end
  end
end

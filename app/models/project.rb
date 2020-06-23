# frozen_string_literal: true

# Project is the documentation about an object built by a fab-user
# It can describe the steps taken by the fab-user to build his object, provide photos, description, attached CAO files, etc.
class Project < ApplicationRecord
  include AASM
  include NotifyWith::NotificationAttachedObject
  include OpenlabSync
  include PgSearch::Model

  # kaminari
  # -- dependency in app/assets/javascripts/controllers/projects.js.erb
  paginates_per 16

  # friendlyId
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :project_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :project_image, allow_destroy: true
  has_many :project_caos, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :project_caos, allow_destroy: true, reject_if: :all_blank

  has_and_belongs_to_many :machines, join_table: 'projects_machines'
  has_and_belongs_to_many :spaces, join_table: 'projects_spaces'
  has_and_belongs_to_many :components, join_table: 'projects_components'
  has_and_belongs_to_many :themes, join_table: 'projects_themes'

  has_many :project_users, dependent: :destroy
  has_many :users, through: :project_users

  belongs_to :author, foreign_key: :author_statistic_profile_id, class_name: 'StatisticProfile'
  belongs_to :licence, foreign_key: :licence_id

  has_many :project_steps, dependent: :destroy
  accepts_nested_attributes_for :project_steps, allow_destroy: true

  # validations
  validates :author, :name, presence: true

  after_save :after_save_and_publish

  aasm column: 'state' do
    state :draft, initial: true
    state :published

    event :publish, after: :notify_admin_when_project_published do
      transitions from: :draft, to: :published
    end
  end

  # scopes
  scope :published, -> { where("state = 'published'") }
  scope :published_or_drafts, lambda { |author_profile|
    where("state = 'published' OR (state = 'draft' AND author_statistic_profile_id = ?)", author_profile)
  }
  scope :user_projects, ->(author_profile) { where('author_statistic_profile_id = ?', author_profile) }
  scope :collaborations, ->(collaborators_ids) { joins(:projects_users).where(projects_users: { user_id: collaborators_ids }) }
  scope :with_machine, ->(machines_ids) { joins(:projects_machines).where(projects_machines: { machine_id: machines_ids }) }
  scope :with_theme, ->(themes_ids) { joins(:projects_themes).where(projects_themes: { theme_id: themes_ids }) }
  scope :with_component, ->(component_ids) { joins(:projects_components).where(projects_components: { component_id: component_ids }) }
  scope :with_space, ->(spaces_ids) { joins(:projects_spaces).where(projects_spaces: { space_id: spaces_ids }) }
  pg_search_scope :search,
                  against: :search_vector,
                  using: {
                    tsearch: {
                      dictionary: Rails.application.secrets.postgresql_language_analyzer,
                      tsvector_column: 'search_vector'
                    },
                    trigram: {
                      word_similarity: true
                    },
                    dmetaphone: {}
                  },
                  ignoring: :accents,
                  order_within_rank: 'created_at DESC'

  private

  def notify_admin_when_project_published
    NotificationCenter.call type: 'notify_admin_when_project_published',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end

  def after_save_and_publish
    return unless saved_change_to_state? && published?

    update_columns(published_at: DateTime.current)
    notify_admin_when_project_published
  end
end

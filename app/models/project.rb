class Project < ActiveRecord::Base
  include AASM
  include NotifyWith::NotificationAttachedObject
  include OpenlabSync

  # elastic initialisations
  include Elasticsearch::Model
  index_name 'fablab'
  document_type 'projects'

  # kaminari
  paginates_per 12 # dependency in projects.coffee

  # friendlyId
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

  # validations
  validates :author, :name, presence: true

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

  ## elastic
  # callbacks
  after_save { ProjectIndexerWorker.perform_async(:index, self.id) }
  after_destroy { ProjectIndexerWorker.perform_async(:delete, self.id) }

  #
  settings do
    mappings dynamic: 'true' do
      indexes 'state', analyzer: 'simple'
      indexes 'tags', analyzer: Rails.application.secrets.elasticsearch_language_analyzer
      indexes 'name', analyzer: Rails.application.secrets.elasticsearch_language_analyzer
      indexes 'description', analyzer: Rails.application.secrets.elasticsearch_language_analyzer
      indexes 'project_steps' do
       indexes 'title', analyzer: Rails.application.secrets.elasticsearch_language_analyzer
       indexes 'description', analyzer: Rails.application.secrets.elasticsearch_language_analyzer
      end
    end
  end

  def as_indexed_json
    Jbuilder.new do |json|
      json.id id
      json.state state
      json.author_id author_id
      json.user_ids user_ids
      json.machine_ids machine_ids
      json.theme_ids theme_ids
      json.component_ids component_ids
      json.tags tags
      json.name name
      json.description description
      json.project_steps project_steps do |project_step|
        json.title project_step.title
        json.description project_step.description
      end
      json.created_at created_at
      json.updated_at updated_at
    end.target!
  end

  def self.search(params, current_user)
    Project.__elasticsearch__.search(build_search_query_from_context(params, current_user))
  end

  def self.build_search_query_from_context(params, current_user)
    search = {
      query: {
        filtered: {
          filter: {
            bool: {
              must: [],
              should: []
            }
          }
        }
      }
    }

    if params['q'].blank? # we sort by created_at if there isn't a query
      search[:sort] = { created_at: { order: :desc } }
    else # otherwise we search for the word (q) in various fields
      search[:query][:filtered][:query] = {
        multi_match: {
          query: params['q'],
          type: 'most_fields',
          fields: %w(tags^4 name^5 description^3 project_steps.title^2 project_steps.description)
        }
      }
    end

    params.each do |name, value| # we filter by themes, components, machines
      if name =~ /(.+_id$)/
        search[:query][:filtered][:filter][:bool][:must] << { term: { "#{name}s" => value } } if value
      end
    end

    if current_user and params.key?('from') # if use select filter 'my project' or 'my collaborations'
      if params['from'] == 'mine'
        search[:query][:filtered][:filter][:bool][:must] << { term: { author_id: current_user.id } }
      end
      if params['from'] == 'collaboration'
        search[:query][:filtered][:filter][:bool][:must] << { term: { user_ids: current_user.id } }
      end
    end

    if current_user # if user is connect, also display his draft projects
      search[:query][:filtered][:filter][:bool][:should] << { term: { state: 'published' } }
      search[:query][:filtered][:filter][:bool][:should] << { term: { author_id: current_user.id } }
      search[:query][:filtered][:filter][:bool][:should] << { term: { user_ids: current_user.id } }
    else # otherwise display only published projects
      search[:query][:filtered][:filter][:bool][:must] << { term: { state: 'published' } }
    end

    search
  end

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

class User < ActiveRecord::Base
  include NotifyWith::NotificationReceiver
  include NotifyWith::NotificationAttachedObject
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :async
  rolify

  extend FriendlyId
  friendly_id :username, use: :slugged

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  has_many :my_projects, foreign_key: :author_id, class_name: 'Project'
  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users

  belongs_to :group

  before_create :assign_default_role
  after_create :notify_admin_when_user_is_created

  attr_accessor :cgu

  validate :cgu_must_accept, if: :new_record?
  validates_presence_of :group_id

  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }

  def to_builder
    Jbuilder.new do |json|
      json.id id
      json.username username
      json.email email
      json.role roles.first.name
      json.group_id group_id
      json.name profile.full_name
      json.profile do
        json.user_avatar do
          json.id profile.user_avatar.id
          json.attachment_url profile.user_avatar.attachment_url
        end if profile.user_avatar
        json.first_name profile.first_name
        json.last_name profile.last_name
        json.gender profile.gender.to_s
        json.birthday profile.birthday.iso8601 if profile.birthday
        json.interest profile.interest
        json.software_mastered profile.software_mastered
        json.address profile.address.address if profile.address
        json.phone profile.phone
      end
      json.last_sign_in_at last_sign_in_at.iso8601 if last_sign_in_at
    end
  end

  def to_json(options)
    to_builder.target!
  end

  def self.admins
    User.with_role(:admin)
  end

  def is_admin?
    has_role? :admin
  end

  def is_member?
    has_role? :member
  end

  def all_projects
    my_projects.to_a.concat projects
  end

  private
  def assign_default_role
    add_role(:member) if self.roles.blank?
  end

  def cgu_must_accept
    errors.add(:cgu, I18n.t('activerecord.errors.messages.empty')) if cgu == '0'
  end

  def notify_admin_when_user_is_created
    NotificationCenter.call type: 'notify_admin_when_user_is_created',
                            receiver: User.admins,
                            attached_object: self
  end

  protected
  def confirmation_required?
    false
  end
end

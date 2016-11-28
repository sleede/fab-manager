class User < ActiveRecord::Base
  include NotifyWith::NotificationReceiver
  include NotifyWith::NotificationAttachedObject
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :async
  rolify

  # enable OmniAuth authentication only if needed
  devise :omniauthable, :omniauth_providers => [AuthProvider.active.strategy_name.to_sym] unless AuthProvider.active.providable_type == DatabaseProvider.name

  extend FriendlyId
  friendly_id :username, use: :slugged

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  has_many :my_projects, foreign_key: :author_id, class_name: 'Project', dependent: :destroy
  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users

  has_many :reservations, dependent: :destroy
  accepts_nested_attributes_for :reservations, allow_destroy: true

  # Les formations sont déjà faites
  has_many :user_trainings, dependent: :destroy
  has_many :trainings, through: :user_trainings

  belongs_to :group

  has_many :subscriptions, dependent: :destroy
  accepts_nested_attributes_for :subscriptions, allow_destroy: true

  has_many :users_credits, dependent: :destroy
  has_many :credits, through: :users_credits

  has_many :training_credits, through: :users_credits, source: :training_credit
  has_many :machine_credits, through: :users_credits, source: :machine_credit

  has_many :invoices, dependent: :destroy

  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_one :wallet, dependent: :destroy

  has_many :exports, dependent: :destroy

  # fix for create admin user
  before_save do
    self.email.downcase! if self.email
  end

  before_create :assign_default_role
  after_create :create_a_wallet
  after_commit :create_stripe_customer, on: [:create]
  after_commit :notify_admin_when_user_is_created, on: :create
  after_update :notify_admin_invoicing_changed, if: :invoicing_disabled_changed?
  after_update :notify_group_changed, if: :group_id_changed?

  attr_accessor :cgu
  delegate :first_name, to: :profile
  delegate :last_name, to: :profile

  validate :cgu_must_accept, if: :new_record?

  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }

  scope :active, -> { where(is_active: true) }
  scope :without_subscription, -> { includes(:subscriptions).where(subscriptions: { user_id: nil }) }
  scope :with_subscription, -> { joins(:subscriptions) }

  def to_builder
    Jbuilder.new do |json|
      json.id id
      json.username username
      json.email email
      json.role roles.first.name
      json.group_id group_id
      json.name profile.full_name
      json.need_completion need_completion?
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
      json.subscribed_plan do
        json.id subscribed_plan.id
        json.name subscribed_plan.name
        json.base_name subscribed_plan.base_name
        json.amount (subscribed_plan.amount / 100.0)
        json.interval subscribed_plan.interval
        json.interval_count subscribed_plan.interval_count
        json.training_credit_nb subscribed_plan.training_credit_nb
        json.training_credits subscribed_plan.training_credits do |tc|
          json.training_id tc.creditable_id
        end
        json.machine_credits subscribed_plan.machine_credits do |mc|
          json.machine_id mc.creditable_id
          json.hours mc.hours
        end
      end if subscribed_plan
      json.subscription do
        json.id subscription.id
        json.expired_at subscription.expired_at.iso8601
        json.canceled_at subscription.canceled_at.iso8601 if subscription.canceled_at
        json.stripe subscription.stp_subscription_id.present?
        json.plan do
          json.id subscription.plan.id
          json.base_name subscription.plan.base_name
          json.name subscription.plan.name
          json.interval subscription.plan.interval
          json.interval_count subscription.plan.interval_count
          json.amount subscription.plan.amount ? (subscription.plan.amount / 100.0) : 0
        end
      end if subscription
      json.training_credits training_credits do |tc|
        json.training_id tc.creditable_id
      end
      json.machine_credits machine_credits do |mc|
        json.machine_id mc.creditable_id
        json.hours_used mc.users_credits.find_by(user_id: id).hours_used
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

  def is_training_machine?(machine)
    return true if is_admin?
    trainings.map do |t|
      t.machines
    end.flatten.uniq.include?(machine)
  end

  def training_reservation_by_machine(machine)
    reservations.where(reservable_type: 'Training', reservable_id: machine.trainings.map(&:id)).first
  end

  def subscribed_plan
    return nil if subscription.nil? or subscription.expired_at < Time.now
    subscription.plan
  end

  def subscription
    subscriptions.last
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

  def generate_admin_invoice(offer_day = false, offer_day_start_at = nil)
    if self.subscription
      if offer_day
        self.subscription.generate_and_save_offer_day_invoice(offer_day_start_at) unless self.invoicing_disabled?
      else
        self.subscription.generate_and_save_invoice unless self.invoicing_disabled?
      end
    end
  end

  def stripe_customer
    Stripe::Customer.retrieve stp_customer_id
  end

  def soft_destroy
    update_attribute(:is_active, false)
    uninvolve_from_projects
  end

  def uninvolve_from_projects
    my_projects.destroy_all
    project_users.destroy_all
  end

  def active_for_authentication?
    super and self.is_active?
  end

  def self.from_omniauth(auth)
    active_provider = AuthProvider.active
    if active_provider.strategy_name != auth.provider
      raise SecurityError, 'The identity provider does not match the activated one'
    end

    where(provider: auth.provider, uid: auth.uid).first_or_create.tap do |user|
      # execute this regardless of whether record exists or not (-> User#tap)
      # this will init or update the user thanks to the information retrieved from the SSO
      user.profile ||= Profile.new
      auth.info.mapping.each do |key, value|
        user.set_data_from_sso_mapping(key, value)
      end
      user.password = Devise.friendly_token[0,20]
    end
  end

  def need_completion?
    profile.gender.nil? or profile.first_name.blank? or profile.last_name.blank? or username.blank? or
    email.blank? or encrypted_password.blank? or group_id.nil? or profile.birthday.blank? or profile.phone.blank?
  end

  ## Retrieve the requested data in the User and user's Profile tables
  ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
  def get_data_from_sso_mapping(sso_mapping)
    parsed = /^(user|profile)\.(.+)$/.match(sso_mapping)
    if parsed[1] == 'user'
      self[parsed[2].to_sym]
    elsif parsed[1] == 'profile'
      case sso_mapping
        when 'profile.avatar'
          self.profile.user_avatar.remote_attachment_url
        when 'profile.address'
          self.profile.address.address
        when 'profile.organization_name'
          self.profile.organization.name
        when 'profile.organization_address'
          self.profile.organization.address.address
        else
          self.profile[parsed[2].to_sym]
      end
    end
  end


  ## Set some data on the current user, according to the sso_key given
  ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
  ## @param data {*} the data to put in the given key. Eg. 'user@example.com'
  def set_data_from_sso_mapping(sso_mapping, data)
    if sso_mapping.to_s.start_with? 'user.'
      self[sso_mapping[5..-1].to_sym] = data unless data.nil?
    elsif sso_mapping.to_s.start_with? 'profile.'
      case sso_mapping.to_s
        when 'profile.avatar'
          self.profile.user_avatar ||= UserAvatar.new
          self.profile.user_avatar.remote_attachment_url = data
        when 'profile.address'
          self.profile.address ||= Address.new
          self.profile.address.address = data
        when 'profile.organization_name'
          self.profile.organization ||= Organization.new
          self.profile.organization.name = data
        when 'profile.organization_address'
          self.profile.organization ||= Organization.new
          self.profile.organization.address ||= Address.new
          self.profile.organization.address.address = data
        else
          self.profile[sso_mapping[8..-1].to_sym] = data unless data.nil?
      end
    end
  end

  ## used to allow the migration of existing users between authentication providers
  def generate_auth_migration_token
    update_attributes(:auth_token => Devise.friendly_token)
  end

  ## link the current user to the given provider (omniauth attributes hash)
  ## and remove the auth_token to mark his account as "migrated"
  def link_with_omniauth_provider(auth)
    active_provider = AuthProvider.active
    if active_provider.strategy_name != auth.provider
      raise SecurityError, 'The identity provider does not match the activated one'
    end

    if User.where(provider: auth.provider, uid: auth.uid).size > 0
      raise DuplicateIndexError, "This #{active_provider.name} account is already linked to an existing user"
    end

    update_attributes(provider: auth.provider, uid: auth.uid, auth_token: nil)
  end

  ## Merge the provided User's SSO details into the current user and drop the provided user to ensure the unity
  ## @param sso_user {User} the provided user will be DELETED after the merge was successful
  def merge_from_sso(sso_user)
    # update the attibutes to link the account to the sso account
    self.provider = sso_user.provider
    self.uid = sso_user.uid

    # remove the token
    self.auth_token = nil
    self.merged_at = DateTime.now

    # check that the email duplication was resolved
    if sso_user.email.end_with? '-duplicate'
      email_addr = sso_user.email.match(/^<([^>]+)>.{20}-duplicate$/)[1]
      unless email_addr == self.email
        raise DuplicateIndexError, email_addr
      end
    end

    # update the user's profile to set the data managed by the SSO
    auth_provider = AuthProvider.from_strategy_name(sso_user.provider)
    auth_provider.sso_fields.each do |field|
      value = sso_user.get_data_from_sso_mapping(field)
      # we do not merge the email field if its end with the special value '-duplicate' as this means
      # that the user is currently merging with the account that have the same email than the sso
      unless field == 'user.email' and value.end_with? '-duplicate'
        self.set_data_from_sso_mapping(field, value)
      end
    end

    # run the account transfert in an SQL transaction to ensure data integrity
    User.transaction do
      # remove the temporary account
      sso_user.destroy
      # finally, save the new details
      self.save!
    end
  end

  def self.mapping
    # we protect some fields as they are designed to be managed by the system and must not be updated externally
    blacklist = %w(id encrypted_password reset_password_token reset_password_sent_at remember_created_at
       sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip confirmation_token confirmed_at
       confirmation_sent_at unconfirmed_email failed_attempts unlock_token locked_at created_at updated_at stp_customer_id slug
       provider auth_token merged_at)
    User.column_types
        .map{|k,v| [k, v.type.to_s]}
        .delete_if { |col| blacklist.include?(col[0]) }
  end

  protected
  def confirmation_required?
    false
  end


  private
  def assign_default_role
    add_role(:member) if self.roles.blank?
  end

  def cached_has_role?(role)
    roles = Rails.cache.fetch(roles_for: { object_id: self.object_id }, expires_in: 1.day, race_condition_ttl: 2.seconds) { self.roles.map(&:name) }
    roles.include?(role.to_s)
  end

  def cgu_must_accept
    errors.add(:cgu, I18n.t('activerecord.errors.messages.empty')) if cgu == '0'
  end

  def create_stripe_customer
    StripeWorker.perform_async(:create_stripe_customer, id)
  end

  def create_a_wallet
    self.create_wallet
  end

  def notify_admin_when_user_is_created
    if need_completion? and not provider.nil?
      NotificationCenter.call type: 'notify_admin_when_user_is_imported',
                              receiver: User.admins,
                              attached_object: self
    else
      NotificationCenter.call type: 'notify_admin_when_user_is_created',
                              receiver: User.admins,
                              attached_object: self
    end
  end

  def notify_group_changed
    if changes[:group_id].first != nil
      ex_group = Group.find(changes[:group_id].first)
      meta_data = { ex_group_name: ex_group.name }

      User.admins.each do |admin|
        notification = Notification.new(meta_data: meta_data)
        notification.send_notification(type: :notify_admin_user_group_changed, attached_object: self).to(admin).deliver_later
      end

      NotificationCenter.call type: :notify_user_user_group_changed,
                              receiver: self,
                              attached_object: self
    end
  end

  def notify_admin_invoicing_changed
    NotificationCenter.call type: 'notify_admin_invoicing_changed',
                            receiver: User.admins,
                            attached_object: self
  end


end

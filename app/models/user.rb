# frozen_string_literal: true

# User is a physical or moral person with its authentication parameters
# It is linked to the Profile model with hold informations about this person (like address, name, etc.)
class User < ActiveRecord::Base
  include NotifyWith::NotificationReceiver
  include NotifyWith::NotificationAttachedObject
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable,
         :confirmable
  rolify

  # enable OmniAuth authentication only if needed
  devise :omniauthable, omniauth_providers: [AuthProvider.active.strategy_name.to_sym] unless
      AuthProvider.active.providable_type == DatabaseProvider.name

  extend FriendlyId
  friendly_id :username, use: :slugged

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  has_one :invoicing_profile, dependent: :nullify
  accepts_nested_attributes_for :invoicing_profile

  has_many :my_projects, foreign_key: :author_id, class_name: 'Project', dependent: :destroy
  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users

  has_many :reservations, dependent: :destroy
  accepts_nested_attributes_for :reservations, allow_destroy: true

  # Trainings that were already passed
  has_many :user_trainings, dependent: :destroy
  has_many :trainings, through: :user_trainings

  belongs_to :group

  has_many :subscriptions, dependent: :destroy
  accepts_nested_attributes_for :subscriptions, allow_destroy: true

  has_many :users_credits, dependent: :destroy
  has_many :credits, through: :users_credits

  has_many :training_credits, through: :users_credits, source: :training_credit
  has_many :machine_credits, through: :users_credits, source: :machine_credit

  has_many :operated_invoices, foreign_key: :operator_id, class_name: 'Invoice', dependent: :nullify

  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_many :exports, dependent: :destroy

  # fix for create admin user
  before_save do
    email&.downcase!
  end

  before_create :assign_default_role
  after_commit :create_stripe_customer, on: [:create]
  after_commit :notify_admin_when_user_is_created, on: :create
  after_update :notify_group_changed, if: :group_id_changed?
  after_save :update_invoicing_profile

  attr_accessor :cgu
  delegate :first_name, to: :profile
  delegate :last_name, to: :profile

  validate :cgu_must_accept, if: :new_record?

  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }

  scope :active, -> { where(is_active: true) }
  scope :without_subscription, -> { includes(:subscriptions).where(subscriptions: { user_id: nil }) }
  scope :with_subscription, -> { joins(:subscriptions) }

  def to_json(*)
    ApplicationController.new.view_context.render(
      partial: 'api/members/member',
      locals: { member: self },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end

  def self.admins
    User.with_role(:admin)
  end

  def self.superadmin
    return unless Rails.application.secrets.superadmin_email.present?

    User.find_by(email: Rails.application.secrets.superadmin_email)
  end

  def training_machine?(machine)
    return true if admin?

    trainings.map(&:machines).flatten.uniq.include?(machine)
  end

  def training_reservation_by_machine(machine)
    reservations.where(reservable_type: 'Training', reservable_id: machine.trainings.map(&:id)).first
  end

  def subscribed_plan
    return nil if subscription.nil? || subscription.expired_at < Time.now

    subscription.plan
  end

  def subscription
    subscriptions.order(:created_at).last
  end

  def admin?
    has_role? :admin
  end

  def member?
    has_role? :member
  end

  def all_projects
    my_projects.to_a.concat projects
  end

  def invoices
    invoicing_profile.invoices
  end

  def wallet
    invoicing_profile.wallet
  end

  def wallet_transactions
    invoicing_profile.wallet_transactions
  end

  def generate_subscription_invoice(operator_id)
    return unless subscription

    subscription.generate_and_save_invoice(operator_id)
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
    super && is_active?
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
    profile.gender.nil? || profile.first_name.blank? || profile.last_name.blank? || username.blank? ||
      email.blank? || encrypted_password.blank? || group_id.nil? || profile.birthday.blank? || profile.phone.blank?
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
        profile.user_avatar.remote_attachment_url
      when 'profile.address'
        invoicing_profile.address.address
      when 'profile.organization_name'
        invoicing_profile.organization.name
      when 'profile.organization_address'
        invoicing_profile.organization.address.address
      else
        profile[parsed[2].to_sym]
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
        profile.user_avatar ||= UserAvatar.new
        profile.user_avatar.remote_attachment_url = data
      when 'profile.address'
        invoicing_profile.address ||= Address.new
        invoicing_profile.address.address = data
      when 'profile.organization_name'
        invoicing_profile.organization ||= Organization.new
        invoicing_profile.organization.name = data
      when 'profile.organization_address'
        invoicing_profile.organization ||= Organization.new
        invoicing_profile.organization.address ||= Address.new
        invoicing_profile.organization.address.address = data
      else
        profile[sso_mapping[8..-1].to_sym] = data unless data.nil?
      end
    end
  end

  ## used to allow the migration of existing users between authentication providers
  def generate_auth_migration_token
    update_attributes(auth_token: Devise.friendly_token)
  end

  ## link the current user to the given provider (omniauth attributes hash)
  ## and remove the auth_token to mark his account as "migrated"
  def link_with_omniauth_provider(auth)
    active_provider = AuthProvider.active
    if active_provider.strategy_name != auth.provider
      raise SecurityError, 'The identity provider does not match the activated one'
    end

    if User.where(provider: auth.provider, uid: auth.uid).size.positive?
      raise DuplicateIndexError, "This #{active_provider.name} account is already linked to an existing user"
    end

    update_attributes(provider: auth.provider, uid: auth.uid, auth_token: nil)
  end

  ## Merge the provided User's SSO details into the current user and drop the provided user to ensure the unity
  ## @param sso_user {User} the provided user will be DELETED after the merge was successful
  def merge_from_sso(sso_user)
    # update the attributes to link the account to the sso account
    self.provider = sso_user.provider
    self.uid = sso_user.uid

    # remove the token
    self.auth_token = nil
    self.merged_at = DateTime.now

    # check that the email duplication was resolved
    if sso_user.email.end_with? '-duplicate'
      email_addr = sso_user.email.match(/^<([^>]+)>.{20}-duplicate$/)[1]
      raise(DuplicateIndexError, email_addr) unless email_addr == email
    end

    # update the user's profile to set the data managed by the SSO
    auth_provider = AuthProvider.from_strategy_name(sso_user.provider)
    auth_provider.sso_fields.each do |field|
      value = sso_user.get_data_from_sso_mapping(field)
      # we do not merge the email field if its end with the special value '-duplicate' as this means
      # that the user is currently merging with the account that have the same email than the sso
      set_data_from_sso_mapping(field, value) unless field == 'user.email' && value.end_with?('-duplicate')
    end

    # run the account transfer in an SQL transaction to ensure data integrity
    User.transaction do
      # remove the temporary account
      sso_user.destroy
      # finally, save the new details
      save!
    end
  end

  def self.mapping
    # we protect some fields as they are designed to be managed by the system and must not be updated externally
    blacklist = %w[id encrypted_password reset_password_token reset_password_sent_at remember_created_at
                   sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip confirmation_token
                   confirmed_at confirmation_sent_at unconfirmed_email failed_attempts unlock_token locked_at created_at
                   updated_at stp_customer_id slug provider auth_token merged_at]
    User.column_types
        .map { |k, v| [k, v.type.to_s] }
        .delete_if { |col| blacklist.include?(col[0]) }
  end

  protected

  def confirmation_required?
    false
  end

  private

  def assign_default_role
    add_role(:member) if roles.blank?
  end

  def cached_has_role?(role)
    roles = Rails.cache.fetch(
      roles_for: { object_id: object_id },
      expires_in: 1.day,
      race_condition_ttl: 2.seconds
    ) { roles.map(&:name) }
    roles.include?(role.to_s)
  end

  def cgu_must_accept
    errors.add(:cgu, I18n.t('activerecord.errors.messages.empty')) if cgu == '0'
  end

  def create_stripe_customer
    StripeWorker.perform_async(:create_stripe_customer, id)
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def notify_admin_when_user_is_created
    if need_completion? && !provider.nil?
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
    return if changes[:group_id].first.nil?

    ex_group = Group.find(changes[:group_id].first)
    meta_data = { ex_group_name: ex_group.name }

    NotificationCenter.call type: :notify_admin_user_group_changed,
                            receiver: User.admins,
                            attached_object: self,
                            meta_data: meta_data

    NotificationCenter.call type: :notify_user_user_group_changed,
                            receiver: self,
                            attached_object: self
  end

  def update_invoicing_profile
    if invoicing_profile.nil?
      InvoicingProfile.create!(
        user: user,
        email: email
      )
    else
      invoicing_profile.update_attributes(
        email: email
      )
    end
  end
end

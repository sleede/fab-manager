# frozen_string_literal: true

# User is a physical or moral person with its authentication parameters
# It is linked to the Profile model with hold information about this person (like address, name, etc.)
class User < ApplicationRecord
  include NotificationAttachedObject
  include SingleSignOnConcern
  include UserRoleConcern
  include UserRessourcesConcern
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable,
         :confirmable
  rolify

  extend FriendlyId
  friendly_id :username, use: :slugged

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  has_one :invoicing_profile, dependent: :nullify
  accepts_nested_attributes_for :invoicing_profile

  has_one :statistic_profile, dependent: :nullify
  accepts_nested_attributes_for :statistic_profile

  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users

  belongs_to :group

  has_many :users_credits, dependent: :destroy
  has_many :credits, through: :users_credits

  has_many :training_credits, through: :users_credits, source: :training_credit
  has_many :machine_credits, through: :users_credits, source: :machine_credit

  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_many :exports, dependent: :destroy
  has_many :imports, dependent: :nullify

  has_one :payment_gateway_object, as: :item, dependent: :nullify

  has_many :accounting_periods, foreign_key: 'closed_by', dependent: :nullify, inverse_of: :user

  has_many :supporting_document_files, dependent: :destroy
  has_many :supporting_document_refusals, dependent: :destroy

  has_many :notifications, as: :receiver, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy

  # fix for create admin user
  before_save do
    email&.downcase!
  end

  before_create :assign_default_role
  after_create :init_dependencies
  after_update :update_invoicing_profile, if: :invoicing_data_was_modified?
  after_update :update_statistic_profile, if: :statistic_data_was_modified?
  before_destroy :remove_orphan_drafts
  after_commit :create_gateway_customer, on: [:create]
  after_commit :notify_admin_when_user_is_created, on: :create

  attr_accessor :cgu

  delegate :first_name, to: :profile
  delegate :last_name, to: :profile
  delegate :subscriptions, to: :statistic_profile
  delegate :reservations, to: :statistic_profile
  delegate :trainings, to: :statistic_profile
  delegate :my_projects, to: :statistic_profile
  delegate :prepaid_packs, to: :statistic_profile
  delegate :wallet, to: :invoicing_profile
  delegate :wallet_transactions, to: :invoicing_profile
  delegate :invoices, to: :invoicing_profile

  validate :cgu_must_accept, if: :new_record?

  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }
  validate :password_complexity

  scope :active, -> { where(is_active: true) }
  scope :without_subscription, -> { includes(statistic_profile: [:subscriptions]).where(subscriptions: { statistic_profile_id: nil }) }
  scope :with_subscription, -> { joins(statistic_profile: [:subscriptions]) }
  scope :not_confirmed, -> { where(confirmed_at: nil) }
  scope :inactive_for_3_years, -> { where('users.last_sign_in_at < ?', 3.years.ago) }

  def to_json(*)
    ApplicationController.new.view_context.render(
      partial: 'api/members/member',
      locals: { member: self },
      formats: [:json],
      handlers: [:jbuilder]
    )
  end

  def generate_subscription_invoice(operator_profile_id)
    return unless subscription

    subscription.generate_and_save_invoice(operator_profile_id)
  end

  def active_for_authentication?
    super && is_active?
  end

  def need_completion?
    statistic_profile.gender.nil? || profile.first_name.blank? || profile.last_name.blank? || username.blank? ||
      email.blank? || encrypted_password.blank? || group_id.nil? || statistic_profile.birthday.blank? ||
      (Setting.get('phone_required') && profile.phone.blank?) ||
      (Setting.get('address_required') && invoicing_profile.address&.address&.blank?)
  end

  def self.mapping
    # we protect some fields as they are designed to be managed by the system and must not be updated externally
    blacklist = %w[id encrypted_password reset_password_token reset_password_sent_at remember_created_at
                   sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip confirmation_token
                   confirmed_at confirmation_sent_at unconfirmed_email failed_attempts unlock_token locked_at created_at
                   updated_at slug provider auth_token merged_at]
    User.columns_hash
        .map { |k, v| [k, v.type.to_s] }
        .delete_if { |col| blacklist.include?(col[0]) }
  end

  # will update the statistic_profile after a group switch or a role update
  def update_statistic_profile
    raise NoProfileError if statistic_profile.nil? || statistic_profile.id.nil?

    statistic_profile.update(
      group_id: group_id,
      role_id: roles.first.id
    )
  end

  def organization?
    !invoicing_profile.organization.nil?
  end

  def notify_group_changed(ex_group, user_invalidated)
    meta_data = { ex_group_name: ex_group.name, user_invalidated: user_invalidated }

    NotificationCenter.call type: :notify_admin_user_group_changed,
                            receiver: User.admins_and_managers,
                            attached_object: self,
                            meta_data: meta_data

    NotificationCenter.call type: :notify_user_user_group_changed,
                            receiver: self,
                            attached_object: self,
                            meta_data: meta_data
  end

  protected

  # remove projects drafts that are not linked to another user
  def remove_orphan_drafts
    orphans = my_projects
              .joins('LEFT JOIN project_users ON projects.id = project_users.project_id')
              .where(project_users: { project_id: nil })
              .where(state: 'draft')
    orphans.map(&:destroy!)
  end

  def confirmation_required?
    Setting.get('confirmation_required') ? super : false
  end

  private

  def assign_default_role
    add_role(:member) if roles.blank?
  end

  def cgu_must_accept
    errors.add(:cgu, I18n.t('activerecord.errors.messages.empty')) if cgu == '0'
  end

  def create_gateway_customer
    PaymentGatewayService.new.create_user(id)
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
                              receiver: User.admins_and_managers,
                              attached_object: self
    end
  end

  def invoicing_data_was_modified?
    saved_change_to_email?
  end

  def statistic_data_was_modified?
    saved_change_to_group_id?
  end

  def init_dependencies
    if invoicing_profile.nil?
      ip = InvoicingProfile.create!(
        user: self,
        email: email,
        first_name: first_name,
        last_name: last_name
      )
    else
      update_invoicing_profile
    end
    if wallet.nil?
      ip ||= invoicing_profile
      Wallet.create!(
        invoicing_profile: ip
      )
    end
    if statistic_profile.nil?
      StatisticProfile.create!(
        user: self,
        group_id: group_id,
        role_id: roles.first.id
      )
    else
      update_statistic_profile
    end
  end

  def update_invoicing_profile
    raise NoProfileError if invoicing_profile.nil?

    invoicing_profile.update(
      email: email,
      first_name: first_name,
      last_name: last_name
    )
  end

  def password_complexity
    return if password.blank? || SecurePassword.secured?(password)

    errors.add I18n.t('app.public.common.password_is_too_weak'), I18n.t('app.public.common.password_is_too_weak_explanations')
  end
end

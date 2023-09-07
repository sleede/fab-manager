# frozen_string_literal: true

# NotificationType defines the different types of Notification.
# To add a new notification type in db, you must add it in:
# - config/initializers/notification_types.rb
# - app/views/api/notifications/_XXXXXX.json.jbuilder
# - app/views/notifications_mailer/XXXXXX.html.erb
# - app/frontend/src/javascript/models/notification-type.ts
# - config/locales/app.logged.en.yml
# - test/fixtures/notification_types.yml
# If you change the name of a category, or create a new one, please add it in:
# - app/frontend/src/javascript/models/notification-type.ts
class NotificationType < ApplicationRecord
  has_many :notifications, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy

  validates :name, uniqueness: true, presence: true
  validates :category, presence: true, inclusion: { in: %w[subscriptions user projects deprecated exports agenda trainings accountings
                                                           app_management wallet payments users_accounts supporting_documents shop] }
  validates :is_configurable, inclusion: { in: [true, false] }

  validate :validate_roles

  scope :for_role, ->(role) { where("roles @> ?", "{#{role}}") }

  private

  def validate_roles
    errors.add(:roles, :invalid) if roles.any? { |r| !r.in?(%w(admin manager)) }
  end
end

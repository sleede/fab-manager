# frozen_string_literal: true

# Provides helper methods for Exports resources and properties
class ExportService
  class << self
    # Check if the last export of the provided type is still accurate or if it must be regenerated
    def last_export(type)
      case type
      when 'users/members'
        last_export_members
      when 'users/reservations'
        last_export_reservations
      when 'users/subscription'
        last_export_subscriptions
      else
        raise TypeError "unknown export type: #{type}"
      end
    end

    private

    def last_export_subscriptions
      Export.where(category: 'users', export_type: 'subscriptions')
            .where('created_at > ?', Subscription.maximum('updated_at'))
            .last
    end

    def last_export_reservations
      Export.where(category: 'users', export_type: 'reservations')
            .where('created_at > ?', Reservation.maximum('updated_at'))
            .last
    end

    def last_export_members
      last_update = [
        User.members.maximum('updated_at'),
        Profile.where(user_id: User.members).maximum('updated_at'),
        InvoicingProfile.where(user_id: User.members).maximum('updated_at'),
        StatisticProfile.where(user_id: User.members).maximum('updated_at'),
        Subscription.maximum('updated_at') || DateTime.current
      ].max

      Export.where(category: 'users', export_type: 'members')
            .where('created_at > ?', last_update)
            .last
    end
  end
end

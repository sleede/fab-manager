# frozen_string_literal: true

# Provides helper methods for Exports resources and properties
class ExportService
  class << self
    # Check if the last export of the provided type is still accurate or if it must be regenerated
    def last_export(type, query = nil, key = nil, extension = nil)
      case type
      when 'users/members'
        last_export_members(query, key, extension)
      when 'users/reservations'
        last_export_reservations(query, key, extension)
      when 'users/subscriptions'
        last_export_subscriptions(query, key, extension)
      when 'availabilities/index'
        last_export_availabilities(query, key, extension)
      when %r{accounting/.*}
        last_export_accounting(type, query, key, extension)
      when %r{statistics/.*}
        last_export_statistics(type, query, key, extension)
      else
        raise TypeError.new("unknown export type: #{type}")
      end
    end

    private

    def query_last_export(category, export_type, query = nil, key = nil, extension = nil)
      export = Export.where(category: category, export_type: export_type)
      export = export.where(query: query) unless query.nil?
      export = export.where(key: key) unless key.nil?
      export = export.where(extension: extension) unless extension.nil?
      export
    end

    def last_export_subscriptions(query, key, extension)
      query_last_export('users', 'subscriptions', query, key, extension)
        .where('created_at > ?', Subscription.maximum('updated_at'))
        .order(created_at: :desc)
        .first
    end

    def last_export_reservations(query, key, extension)
      query_last_export('users', 'reservations', query, key, extension)
        .where('created_at > ?', Reservation.maximum('updated_at'))
        .order(created_at: :desc)
        .first
    end

    def last_export_members(query, key, extension)
      last_update = [
        User.members.maximum('updated_at'),
        Profile.where(user_id: User.members).maximum('updated_at'),
        InvoicingProfile.where(user_id: User.members).maximum('updated_at'),
        StatisticProfile.where(user_id: User.members).maximum('updated_at'),
        Subscription.maximum('updated_at') || Time.current
      ].max

      query_last_export('users', 'members', query, key, extension)
        .where('created_at > ?', last_update)
        .order(created_at: :desc)
        .first
    end

    def last_export_availabilities(query, key, extension)
      query_last_export('availabilities', 'index', query, key, extension)
        .where('created_at > ?', [Availability.maximum('updated_at'), Reservation.maximum('updated_at')].max)
        .order(created_at: :desc)
        .first
    end

    def last_export_accounting(type, query, key, extension)
      query_last_export('accounting', type.split('/')[1], query, key, extension)
        .where('created_at > ?', Invoice.maximum('updated_at'))
        .order(created_at: :desc)
        .first
    end

    def last_export_statistics(type, query, key, extension)
      query_last_export('statistics', type.split('/')[1], query, key, extension)
        .order(created_at: :desc)
        .first
    end
  end
end

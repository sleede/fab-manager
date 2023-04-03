# frozen_string_literal: true

# Provides helper methods for listing Users
class Members::ListService
  class << self
    def list(params)
      @query = User.includes(:profile, :group, :statistic_profile)
                   .joins(:profile,
                          :statistic_profile,
                          :group,
                          :roles,
                          'LEFT JOIN (
                              SELECT *
                              FROM "subscriptions" AS s1
                              INNER JOIN (
                                  SELECT MAX("created_at") AS "s2_created_at", "statistic_profile_id" AS "s2_statistic_profile_id"
                                  FROM "subscriptions"
                                  GROUP BY "statistic_profile_id"
                              ) AS s2
                              ON "s1"."statistic_profile_id" =  "s2"."s2_statistic_profile_id"
                              WHERE "s1"."expiration_date" > now()::date
                          ) AS "subscriptions" ON "subscriptions"."statistic_profile_id" = "statistic_profiles"."id" ' \
                          'LEFT JOIN "plans" ON "plans"."id" = "subscriptions"."plan_id"')
                   .where("users.is_active = 'true' AND roles.name = 'member'")
                   .order(list_order(params))

      # ILIKE => PostgreSQL case-insensitive LIKE
      if params[:search].size.positive?
        @query = @query.where('users.username ILIKE :search OR ' \
                              'profiles.first_name ILIKE :search OR ' \
                              'profiles.last_name ILIKE :search OR ' \
                              'profiles.phone ILIKE :search OR ' \
                              'email ILIKE :search OR ' \
                              'groups.name ILIKE :search OR ' \
                              'plans.base_name ILIKE :search', search: "%#{params[:search]}%")
      end

      filter = params[:filter].presence_in(%w[inactive_for_3_years not_confirmed]) || nil
      @query = @query.send(filter) if filter

      @query
    end

    def search(current_user, query, subscription)
      members = User.includes(:profile, :statistic_profile, invoicing_profile: [:address])
                    .joins(:profile,
                           :statistic_profile,
                           :roles,
                           'LEFT JOIN "subscriptions" ON "subscriptions"."statistic_profile_id" = "statistic_profiles"."id" AND ' \
                           '"subscriptions"."created_at" = ( ' \
                           'SELECT max("created_at") ' \
                           'FROM "subscriptions" ' \
                           'WHERE "statistic_profile_id" = "statistic_profiles"."id")')
                    .where("users.is_active = 'true'")
                    .limit(50)
      query.downcase.split.each do |word|
        members = members.where('lower(f_unaccent(users.username)) ~ :search OR ' \
                                'lower(f_unaccent(profiles.first_name)) ~ :search OR ' \
                                'lower(f_unaccent(profiles.last_name)) ~ :search',
                                search: word)
      end

      if current_user.member?
        # non-admin can only retrieve users with "public profiles"
        members = members.where("users.is_allow_contact = 'true'")
      elsif subscription == 'true'
        # only admins have the ability to filter by subscription
        members = members.where('subscriptions.id IS NOT NULL AND subscriptions.expiration_date >= :now', now: Time.zone.today.to_s)
      elsif subscription == 'false'
        members = members.where('subscriptions.id IS NULL OR subscriptions.expiration_date < :now', now: Time.zone.today.to_s)
      end

      members.to_a.filter(&:valid?)
    end

    private

    def list_order(params)
      direction = (params[:order_by][0] == '-' ? 'DESC' : 'ASC')
      order_key = (params[:order_by][0] == '-' ? params[:order_by][1, params[:order_by].size] : params[:order_by])
      limit = params[:size]
      offset = ((params[:page]&.to_i || 1) - 1) * (params[:size]&.to_i || 1)

      order_key = case order_key
                  when 'username'
                    'users.username'
                  when 'last_name'
                    'profiles.last_name'
                  when 'first_name'
                    'profiles.first_name'
                  when 'email'
                    'users.email'
                  when 'phone'
                    'profiles.phone'
                  when 'group'
                    'groups.name'
                  when 'plan'
                    'plans.base_name'
                  else
                    'users.id'
                  end

      Arel.sql("#{order_key} #{direction}, users.id ASC LIMIT #{limit} OFFSET #{offset}")
    end
  end
end

# frozen_string_literal: true

# Provides helper methods for listing Users
class Members::ListService
  class << self
    def list(params)
      @query = User.includes(:profile, :group, :subscriptions)
                   .joins(:profile,
                          :group,
                          :roles,
                          'LEFT JOIN "subscriptions" ON "subscriptions"."user_id" = "users"."id" ' \
                          'LEFT JOIN "plans" ON "plans"."id" = "subscriptions"."plan_id"')
                   .where("users.is_active = 'true' AND roles.name = 'member'")
                   .order(list_order(params))
                   .page(params[:page])
                   .per(params[:size])

      # ILIKE => PostgreSQL case-insensitive LIKE
      if params[:search].size.positive?
        @query = @query.where('profiles.first_name ILIKE :search OR ' \
                              'profiles.last_name ILIKE :search OR '  \
                              'profiles.phone ILIKE :search OR ' \
                              'email ILIKE :search OR ' \
                              'groups.name ILIKE :search OR ' \
                              'plans.base_name ILIKE :search', search: "%#{params[:search]}%")
      end

      @query
    end

    def search(current_user, query, subscription)
      members = User.includes(:profile)
                    .joins(:profile,
                           :roles,
                           'LEFT JOIN "subscriptions" ON "subscriptions"."user_id" = "users"."id" AND ' \
                           '"subscriptions"."created_at" = ( ' \
                             'SELECT max("created_at") ' \
                             'FROM "subscriptions" ' \
                             'WHERE "user_id" = "users"."id")')
                    .where("users.is_active = 'true' AND roles.name = 'member'")
                    .limit(50)
      query.downcase.split(' ').each do |word|
        members = members.where('lower(f_unaccent(profiles.first_name)) ~ :search OR ' \
                                'lower(f_unaccent(profiles.last_name)) ~ :search',
                                search: word)
      end


      if current_user.member?
        # non-admin can only retrieve users with "public profiles"
        members = members.where("users.is_allow_contact = 'true'")
      elsif subscription == 'true'
        # only admins have the ability to filter by subscription
        members = members.where('subscriptions.id IS NOT NULL AND subscriptions.expiration_date >= :now', now: Date.today.to_s)
      elsif subscription == 'false'
        members = members.where('subscriptions.id IS NULL OR subscriptions.expiration_date < :now', now: Date.today.to_s)
      end

      members.to_a
    end

    private

    def list_order(params)
      direction = (params[:order_by][0] == '-' ? 'DESC' : 'ASC')
      order_key = (params[:order_by][0] == '-' ? params[:order_by][1, params[:order_by].size] : params[:order_by])

      order_key = case order_key
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

      "#{order_key} #{direction}"
    end
  end
end

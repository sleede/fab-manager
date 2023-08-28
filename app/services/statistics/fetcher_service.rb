# frozen_string_literal: true

# Fetch data from the PostgreSQL database and prepare them
# to be used in the statistics generation
class Statistics::FetcherService
  include Statistics::Concerns::HelpersConcern
  include Statistics::Concerns::ComputeConcern
  include Statistics::Concerns::ProjectsConcern
  include Statistics::Concerns::StoreOrdersConcern

  class << self
    def subscriptions_list(options = default_options)
      result = []
      InvoiceItem.where("object_type = '#{Subscription.name}' AND invoice_items.created_at >= :start_date " \
                        'AND invoice_items.created_at <= :end_date', options)
                 .eager_load(invoice: [:coupon]).find_each do |i|
        next if i.invoice.is_a?(Avoir)

        sub = i.object

        ca = i.amount.to_i
        cs = CouponService.new
        ca = cs.ventilate(cs.invoice_total_no_coupon(i.invoice), ca, i.invoice.coupon) unless i.invoice.coupon_id.nil?
        ca /= 100.00
        profile = sub.statistic_profile
        p = sub.plan
        result.push({ date: i.created_at.to_date,
                      plan: p.group.slug,
                      plan_id: p.id,
                      plan_interval: p.interval,
                      plan_interval_count: p.interval_count,
                      plan_group_name: p.group.name,
                      slug: p.slug,
                      duration: p.find_statistic_type.key,
                      subscription_id: sub.id,
                      invoice_item_id: i.id,
                      coupon: i.invoice.coupon&.code,
                      ca: ca }.merge(user_info(profile)))
      end
      result
    end

    # @param options [Hash]
    # @yield [reservation]
    # @yieldparam [Hash]
    def each_machine_reservation(options = default_options)
      Reservation
        .where("reservable_type = 'Machine' AND slots_reservations.canceled_at IS NULL AND " \
               'reservations.created_at >= :start_date AND reservations.created_at <= :end_date', options)
        .eager_load(:slots, :slots_reservations, :invoice_items, :reservation_context, statistic_profile: [:group])
        .find_each do |r|
        next unless r.reservable

        profile = r.statistic_profile
        result = { date: r.created_at.to_date,
                   reservation_id: r.id,
                   machine_id: r.reservable.id,
                   machine_type: r.reservable.friendly_id,
                   machine_name: r.reservable.name,
                   slot_dates: r.slots.map(&:start_at).map(&:to_date),
                   nb_hours: (r.slots.map(&:duration).map(&:to_i).reduce(:+) / 3600.0).to_f,
                   ca: calcul_ca(r.original_invoice),
                   reservation_context_id: r.reservation_context_id,
                   coupon: r.original_invoice.coupon&.code
                  }.merge(user_info(profile))
        yield result
      end
    end

    # @param options [Hash]
    # @yield [reservation]
    # @yieldparam [Hash]
    def each_space_reservation(options = default_options)
      Reservation
        .where("reservable_type = 'Space' AND slots_reservations.canceled_at IS NULL AND " \
               'reservations.created_at >= :start_date AND reservations.created_at <= :end_date', options)
        .eager_load(:slots, :slots_reservations, :invoice_items, :reservation_context, statistic_profile: [:group])
        .find_each do |r|
        next unless r.reservable

        profile = r.statistic_profile
        result = { date: r.created_at.to_date,
                   reservation_id: r.id,
                   space_id: r.reservable.id,
                   space_name: r.reservable.name,
                   space_type: r.reservable.slug,
                   slot_dates: r.slots.map(&:start_at).map(&:to_date),
                   nb_hours: (r.slots.map(&:duration).map(&:to_i).reduce(:+) / 3600.0).to_f,
                   ca: calcul_ca(r.original_invoice),
                   reservation_context_id: r.reservation_context_id,
                   coupon: r.original_invoice.coupon&.code
                  }.merge(user_info(profile))
        yield result
      end
    end

    # @param options [Hash]
    # @yield [reservation]
    # @yieldparam [Hash]
    def each_training_reservation(options = default_options)
      Reservation
        .where("reservable_type = 'Training' AND slots_reservations.canceled_at IS NULL AND " \
               'reservations.created_at >= :start_date AND reservations.created_at <= :end_date', options)
        .eager_load(:slots, :slots_reservations, :invoice_items, :reservation_context, statistic_profile: [:group])
        .find_each do |r|
        next unless r.reservable

        profile = r.statistic_profile
        slot = r.slots.first
        result = { date: r.created_at.to_date,
                   reservation_id: r.id,
                   training_id: r.reservable.id,
                   training_type: r.reservable.friendly_id,
                   training_name: r.reservable.name,
                   training_date: slot.start_at.to_date,
                   nb_hours: difference_in_hours(slot.start_at, slot.end_at),
                   ca: calcul_ca(r.original_invoice),
                   reservation_context_id: r.reservation_context_id,
                   coupon: r.original_invoice&.coupon&.code
                 }.merge(user_info(profile))
        yield result
      end
    end

    # @param options [Hash]
    # @yield [reservation]
    # @yieldparam [Hash]
    def each_event_reservation(options = default_options)
      Reservation
        .where("reservable_type = 'Event' AND slots_reservations.canceled_at IS NULL AND " \
               'reservations.created_at >= :start_date AND reservations.created_at <= :end_date', options)
        .eager_load(:slots, :slots_reservations, :invoice_items, statistic_profile: [:group])
        .find_each do |r|
        next unless r.reservable
        next unless r.original_invoice

        profile = r.statistic_profile
        slot = r.slots.first
        result = { date: r.created_at.to_date,
                   reservation_id: r.id,
                   event_id: r.reservable.id,
                   event_type: r.reservable.category.slug,
                   event_name: r.reservable.name,
                   event_date: slot.start_at.to_date,
                   event_theme: (r.reservable.event_themes.first ? r.reservable.event_themes.first.name : ''),
                   age_range: (r.reservable.age_range_id ? r.reservable.age_range.name : ''),
                   nb_places: r.total_booked_seats,
                   nb_hours: difference_in_hours(slot.start_at, slot.end_at),
                   coupon: r.original_invoice.coupon&.code,
                   ca: calcul_ca(r.original_invoice) }.merge(user_info(profile))
        yield result
      end
    end

    def members_ca_list(options = default_options)
      subscriptions_ca_list = subscriptions_list(options)
      reservations_ca_list = []
      avoirs_ca_list = []
      users_list = []
      Reservation.where('reservations.created_at >= :start_date AND reservations.created_at <= :end_date', options)
                 .eager_load(:slots, :invoice_items, statistic_profile: [:group])
                 .find_each do |r|
        next unless r.reservable

        reservations_ca_list.push(
          { date: r.created_at.to_date, ca: calcul_ca(r.original_invoice) || 0 }.merge(user_info(r.statistic_profile))
        )
      end
      Avoir.where('invoices.created_at >= :start_date AND invoices.created_at <= :end_date', options)
           .eager_load(:invoice_items, statistic_profile: [:group])
           .find_each do |i|
        # the following line is a workaround for issue #196
        profile = i.statistic_profile || i.main_item.object&.wallet&.user&.statistic_profile
        avoirs_ca_list.push({ date: i.created_at.to_date, ca: calcul_avoir_ca(i) || 0 }.merge(user_info(profile)))
      end
      reservations_ca_list.concat(subscriptions_ca_list).concat(avoirs_ca_list).each do |e|
        profile = StatisticProfile.find(e[:statistic_profile_id])
        u = find_or_create_user_info(profile, users_list)
        u[:date] = e[:date]
        add_ca(u, e[:ca], users_list)
      end
      users_list
    end

    # @param options [Hash]
    # @yield [reservation]
    # @yieldparam [Hash]
    def each_member(options = default_options)
      member = Role.find_by(name: 'member')
      StatisticProfile.where('role_id = :member AND created_at >= :start_date AND created_at <= :end_date',
                             options.merge(member: member.id))
                      .find_each do |sp|
        next if sp.user&.need_completion?

        result = { date: sp.created_at.to_date }.merge(user_info(sp))
        yield result
      end
    end

    # @param options [Hash]
    # @yield [reservation]
    # @yieldparam [Hash]
    def each_project(options = default_options)
      Project.where('projects.published_at >= :start_date AND projects.published_at <= :end_date', options)
             .eager_load(:licence, :themes, :components, :machines, :project_users, author: [:group])
             .find_each do |p|
        result = { date: p.created_at.to_date }.merge(user_info(p.author)).merge(project_info(p))
        yield result
      end
    end

    # @param states [Array<String>]
    # @param options [Hash]
    # @yield [reservation]
    # @yieldparam [Hash]
    def each_store_order(states, options = default_options)
      Order.includes(order_items: [:orderable])
           .joins(:order_items, :order_activities)
           .where(order_items: { orderable_type: 'Product' })
           .where(orders: { state: states })
           .where('order_activities.created_at >= :start_date AND order_activities.created_at <= :end_date', options)
           .group('orders.id')
           .find_each do |o|
        result = { date: o.created_at.to_date, ca: calcul_ca(o.invoice), coupon: o.invoice.coupon&.code }
                 .merge(user_info(o.statistic_profile))
                 .merge(store_order_info(o))
        yield result
      end
    end

    private

    def add_ca(profile, new_ca, users_list)
      if profile[:ca]
        profile[:ca] += new_ca || 0
      else
        profile[:ca] = new_ca || 0
        users_list.push profile
      end
    end

    def find_or_create_user_info(profile, list)
      found = list.find do |l|
        l[:statistic_profile_id] == profile.id
      end
      found || user_info(profile)
    end

    def user_info(statistic_profile)
      return {} unless statistic_profile

      {
        statistic_profile_id: statistic_profile.id,
        user_id: statistic_profile.user_id,
        gender: statistic_profile.str_gender,
        age: statistic_profile.age,
        group: statistic_profile.group ? statistic_profile.group.slug : nil
      }
    end
  end
end

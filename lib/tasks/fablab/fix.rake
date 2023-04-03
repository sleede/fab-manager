# frozen_string_literal: true

# Correctives for bugs or upgrades migrations tasks
namespace :fablab do
  namespace :fix do
    desc '[release 2.3.0] update reservations referencing reservables not present in database'
    task reservations_not_existing_reservable: :environment do
      ActiveRecord::Base.logger = Logger.new($stdout)
      ActiveRecord::Base.connection.execute(
        'UPDATE reservations SET reservable_type = NULL, reservable_id = NULL ' \
        'WHERE NOT EXISTS (SELECT 1 FROM events WHERE events.id = reservations.reservable_id) ' \
        "AND reservations.reservable_type = 'Event'"
      )
    end

    desc '[release 2.4.0] put every non-categorized events into a new category called "No Category", to ease re-categorization'
    task assign_category_to_uncategorized_events: :environment do
      c = Category.find_or_create_by!(name: 'No category')
      Event.where(category: nil).each do |e|
        e.category = c
        e.save!
      end
    end

    desc '[release 2.4.11] fix is_rolling for edited plans'
    task rolling_plans: :environment do
      Plan.where(is_rolling: nil).each do |p|
        if p.is_rolling.nil? && p.is_rolling != false
          p.is_rolling = true
          p.save!
        end
      end
    end

    desc '[release 2.5.0] create missing plans in statistics'
    task new_plans_statistics: :environment do
      StatisticSubType.where(key: nil).each do |sst|
        p = Plan.find_by(name: sst.label)
        if p
          sst.key = p.slug
          sst.save!
        end
      end
    end

    desc '[release 2.5.5] create missing space prices'
    task new_group_space_prices: :environment do
      Space.all.each do |space|
        Group.all.each do |group|
          Price.find(priceable: space, group: group)
        rescue ActiveRecord::RecordNotFound
          Price.create(priceable: space, group: group, amount: 0)
        end
      end
    end

    desc '[release 2.5.11] put all admins in a special group'
    task migrate_admins_group: :environment do
      admins = Group.find_by(slug: 'admins')
      User.all.each do |user|
        if user.admin?
          user.group = admins
          user.save!
        end
      end
    end

    desc '[release 2.5.14] fix times of recursive events that crosses DST periods'
    task recursive_events_over_DST: :environment do
      def dst_correction(reference, datetime)
        res = datetime.in_time_zone(reference.time_zone.tzinfo.name)
        res -= 1.hour if res.dst? && !reference.dst?
        res += 1.hour if reference.dst? && !res.dst?
        res
      end
      failed_ids = []
      groups = Event.group(:recurrence_id).count
      groups.each_key do |recurrent_event_id|
        next unless recurrent_event_id

        begin
          initial_event = Event.find(recurrent_event_id)
          Event.where(recurrence_id: recurrent_event_id).where.not(id: recurrent_event_id).each do |event|
            availability = event.availability
            next if initial_event.availability.start_at.hour == availability.start_at.hour

            availability.start_at = dst_correction(initial_event.availability.start_at, availability.start_at)
            availability.end_at = dst_correction(initial_event.availability.end_at, availability.end_at)
            availability.save!
          end
        rescue ActiveRecord::RecordNotFound
          failed_ids.push recurrent_event_id
        end
      end

      if failed_ids.size.positive?
        puts "WARNING: The events with IDs #{failed_ids} were not found.\n These were initial events of a recurrence.\n\n" \
             "You may have to correct the following events manually (IDs): #{Event.where(recurrence_id: failed_ids).map(&:id)}"
      end
    end

    desc '[release 2.6.6] reset slug in events categories'
    task categories_slugs: :environment do
      Category.all.each do |cat|
        # rubocop:disable Layout/LineLength
        `curl -XPOST http://#{ENV.fetch('ELASTICSEARCH_HOST', nil)}:9200/stats/event/_update_by_query?conflicts=proceed\\&refresh\\&wait_for_completion -d '
        {
          "script": {
            "source": "ctx._source.subType = params.slug",
            "lang": "painless",
            "params": {
              "slug": "#{cat.slug}"
            }
          },
          "query": {
            "term": {
              "subType": "#{cat.name}"
            }
          }
        }';`
        # rubocop:enable Layout/LineLength
      end
    end

    desc '[release 2.4.10] set slugs to plans'
    task set_plans_slugs: :environment do
      # this will maintain compatibility with existing statistics
      Plan.all.each do |p|
        p.slug = p.stp_plan_id
        p.save
      end
    end

    desc '[release 3.1.2] fix users with invalid group_id'
    task users_group_ids: :environment do
      User.where.not(group_id: Group.all.map(&:id)).each do |u|
        u.update_columns(group_id: Group.first.id, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

        meta_data = { ex_group_name: 'invalid group' }

        NotificationCenter.call type: :notify_admin_user_group_changed,
                                receiver: User.admins,
                                attached_object: u,
                                meta_data: meta_data

        NotificationCenter.call type: :notify_user_user_group_changed,
                                receiver: u,
                                attached_object: u
      end
    end

    desc '[release 4.3.0] add name to theme stylesheet'
    task name_stylesheet: :environment do
      Stylesheet.order(:created_at).first&.update(
        name: 'theme'
      )
    end

    desc '[release 4.3.3] add statistic_profile_id to refund invoices for WalletTransactions'
    task avoirs_wallet_transaction: :environment do
      Avoir.where(invoiced_type: WalletTransaction.name).each do |a|
        next unless a.statistic_profile_id.nil?

        begin
          a.statistic_profile_id = a.invoiced.wallet.user&.statistic_profile&.id
          a.save!
        rescue ActiveRecord::RecordInvalid => e
          printf "Unable to modify the refund invoice (id %<id>s): %<error>s\nIgnoring that record...\n", id: a.id, error: e
        end
      end
    end

    desc '[release 4.4.2] add missing role to StatisticProfile'
    task role_in_statistic_profile: :environment do
      puts "Fixing #{StatisticProfile.where(role_id: nil).count} bugged profiles...\n"
      StatisticProfile.where(role_id: nil).each do |sp|
        role_id = sp.user&.roles&.first&.id
        sp.role_id = role_id
        sp.save!
      end
    end

    desc '[release 4.4.3] fix duration of recurring availabilities'
    task availabilities_duration: :environment do
      Availability.select('occurrence_id').where(is_recurrent: true).group('occurrence_id').each do |a|
        occurrences = Availability.where(occurrence_id: a.occurrence_id)
        next unless occurrences.map(&:slot_duration).uniq.size > 1

        duration = occurrences.map(&:slot_duration).uniq.detect { |e| !e.nil? }
        occurrences.each do |o|
          o.update(slot_duration: duration)
        end
      end
    end

    desc '[release 4.7.9] fix invoicing profiles without names'
    task invoices_without_names: :environment do
      InvoicingProfile.where('(first_name IS NULL OR last_name IS NULL) AND user_id IS NOT NULL').each do |ip|
        ip.update(first_name: ip.user.profile.first_name)
        ip.update(last_name: ip.user.profile.last_name)
      end
    end

    desc '[release 5.3.8] fix invoicing profiles without names and email'
    task invoices_without_names_and_email: :environment do
      InvoicingProfile.where('(first_name IS NULL OR last_name IS NULL OR email IS NULL) AND user_id IS NOT NULL').each do |ip|
        ip.update(first_name: ip.user.profile.first_name)
        ip.update(last_name: ip.user.profile.last_name)
        ip.update(email: ip.user.email)
      end
    end

    desc '[release 5.4.24] fix prepaid pack hours dont count down after a reservation of machine'
    task :prepaid_pack_count_down, %i[start_date end_date] => :environment do |_task, args|
      # set start date to the date of deployment of v5.4.13 that product the bug
      start_date = Time.zone.parse('2022-07-28T10:00:00+02:00')
      if args.start_date
        begin
          start_date = Time.zone.parse(args.start_date)
        rescue ArgumentError => e
          raise e
        end
      end
      # set end date to the date of deployment of v5.4.24 after fix the bug
      end_date = Time.zone.parse('2022-10-14T18:40:00+02:00')
      if args.end_date
        begin
          end_date = Time.zone.parse(args.end_date)
        rescue ArgumentError => e
          raise e
        end
      end
      # find all machines that has prepaid pack
      machine_ids = PrepaidPack.where(disabled: nil).all.map(&:priceable_id).uniq
      # find all memders that bought a prepaid pack
      statistic_profile_ids = StatisticProfilePrepaidPack.all.map(&:statistic_profile_id).uniq
      # find the reservations that use prepaid pack by machine_ids, members and preriod
      reservations = Reservation.where(reservable_type: 'Machine', reservable_id: machine_ids, statistic_profile_id: statistic_profile_ids,
                                       created_at: start_date..end_date).order(statistic_profile_id: :asc, created_at: :asc)
      infos = []
      reservations.each do |reservation|
        # find pack by pack's created_at before reservation's create_at and pack's expries_at before start_date
        packs = StatisticProfilePrepaidPack
                .includes(:prepaid_pack)
                .references(:prepaid_packs)
                .where(prepaid_packs: { priceable_id: reservation.reservable.id })
                .where(prepaid_packs: { priceable_type: reservation.reservable.class.name })
                .where(statistic_profile_id: reservation.statistic_profile_id)
                .where('statistic_profile_prepaid_packs.created_at <= ?', reservation.created_at)
                .where('expires_at is NULL or expires_at > ?', start_date)
                .order(created_at: :asc)

        # passe reservation if cannot find any pack
        next if packs.empty?

        user = reservation.statistic_profile.user
        pack = packs.last

        slots_minutes = reservation.slots.map do |slot|
          (slot.end_at.to_time - slot.start_at.to_time) / 60.0
        end
        # get reservation total minutes
        reservation_minutes = slots_minutes.reduce(:+) || 0

        info = {
          user: "#{user.profile.full_name} - #{user.email}",
          reservation: "Reservation #{reservation.original_invoice.reference} for the machine #{reservation.reservable.name} " \
                       "by #{reservation_minutes / 60.0} hours at #{I18n.l(reservation.created_at.to_date)}",
          pack_before: "Prepaid pack of hours has used #{pack.minutes_used / 60.0} hours / #{pack.prepaid_pack.minutes / 60.0} hours"
        }

        if pack.minutes_used == pack.prepaid_pack.minutes && pack.updated_at > start_date
          info[:pack_after] = 'Reservation minutes is exceed prepaid pack of hours'
          infos.push(info)
        elsif pack.minutes_used < pack.prepaid_pack.minutes
          PrepaidPackService.update_user_minutes(user, reservation)
          pack.reload
          info[:pack_after] = "Prepaid pack of hours used #{pack.minutes_used / 60.0} hours after paid this reservation"
          infos.push(info)
        end
      end

      infos.each do |i|
        puts i
      end
    end

    desc '[release 5.6.6] fix invoice items in error'
    task invoice_items_in_error: :environment do
      next if InvoiceItem.where(object_type: 'Error').count.zero?

      InvoiceItem.where(object_type: 'Error').update_all(object_id: 0) # rubocop:disable Rails/SkipsModelValidations

      FabManager::Application.load_tasks if Rake::Task.tasks.empty?
      Rake::Task['fablab:chain:invoices_items'].invoke
    end

    desc '[release 5.8.2] fix operator of self-bought carts'
    task cart_operator: :environment do |_task, _args|
      Order.where.not(statistic_profile_id: nil).find_each do |order|
        order.update(operator_profile_id: order.user&.invoicing_profile&.id)
      end
      Order.where.not(operator_profile_id: nil).find_each do |order|
        order.update(statistic_profile_id: order.operator_profile&.user&.statistic_profile&.id)
      end
    end

    desc '[release 5.8.2] fix prepaid packs minutes_used'
    task pack_minutes_used: :environment do |_task, _args|
      StatisticProfilePrepaidPack.find_each do |sppp|
        previous_packs = sppp.statistic_profile.statistic_profile_prepaid_packs
                             .includes(:prepaid_pack)
                             .where(prepaid_packs: { priceable: sppp.prepaid_pack.priceable })
                             .where("statistic_profile_prepaid_packs.created_at <= '#{sppp.created_at.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')}'")
                             .order('statistic_profile_prepaid_packs.created_at')
        remaining = {}
        previous_packs.each do |pack|
          available_minutes = pack.prepaid_pack.minutes
          reservations = Reservation.where(reservable: sppp.prepaid_pack.priceable)
                                    .where(statistic_profile_id: sppp.statistic_profile_id)
                                    .where("created_at > '#{pack.created_at.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')}'")
          reservations.each do |reservation|
            next if available_minutes.zero?

            # if the previous pack has not covered all the duration of this reservation, we substract the remaining minutes from the current pack
            if remaining[reservation.id]
              if remaining[reservation.id] > available_minutes
                consumed = available_minutes
                remaining[reservation.id] = remaining[reservation.id] - available_minutes
              else
                consumed = remaining[reservation.id]
                remaining.except!(reservation.id)
              end
            else
              # if there was no remaining from the previous pack, we substract the reservation duration from the current pack
              reservation_minutes = reservation.slots.map { |slot| (slot.end_at.to_time - slot.start_at.to_time) / 60.0 }.reduce(:+) || 0
              if reservation_minutes > available_minutes
                consumed = available_minutes
                remaining[reservation.id] = reservation_minutes - consumed
              else
                consumed = reservation_minutes
              end
            end
            available_minutes -= consumed
            PrepaidPackReservation.find_or_create_by!(statistic_profile_prepaid_pack: pack, reservation: reservation, consumed_minutes: consumed)
          end
          pack.update(minutes_used: pack.prepaid_pack.minutes - available_minutes)
        end
      end
    end
  end
end

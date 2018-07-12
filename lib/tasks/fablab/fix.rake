namespace :fablab do
  namespace :fix do
    task reservations_not_existing_reservable: :environment do
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.connection.execute(
        'UPDATE reservations SET reservable_type = NULL, reservable_id = NULL'\
        ' WHERE NOT EXISTS (SELECT 1 FROM events WHERE events.id = reservations.reservable_id)'\
        ' AND reservations.reservable_type = \'Event\''
      )
    end

    task assign_category_to_uncategorized_events: :environment do
      c = Category.find_or_create_by!({name: 'No category'})
      Event.where(category: nil).each do |e|
        e.category = c
        e.save!
      end
    end

    task rolling_plans: :environment do
      Plan.where(is_rolling: nil).each do |p|
        if p.is_rolling.nil? and p.is_rolling != false
          p.is_rolling = true
          p.save!
        end
      end
    end

    task new_plans_statistics: :environment do
      StatisticSubType.where(key: nil).each do |sst|
        p = Plan.find_by(name: sst.label)
        if p
          sst.key = p.slug
          sst.save!
        end
      end
    end

    task new_group_space_prices: :environment do
      Space.all.each do |space|
        Group.all.each do |group|
          begin
            Price.find(priceable: space, group: group)
          rescue ActiveRecord::RecordNotFound
            Price.create(priceable: space, group: group, amount: 0)
          end
        end
      end
    end

    task migrate_admins_group: :environment do
      admins = Group.find_by(slug: 'admins')
      User.all.each do |user|
        if user.is_admin?
          user.group = admins
          user.save!
        end
      end
    end

    task recursive_events_over_DST: :environment do
      include ApplicationHelper
      failed_ids = []
      groups = Event.group(:recurrence_id).count
      groups.keys.each do |recurrent_event_id|
        if recurrent_event_id
          begin
            initial_event = Event.find(recurrent_event_id)
            Event.where(recurrence_id: recurrent_event_id).where.not(id: recurrent_event_id).each do |event|
              availability = event.availability
              if initial_event.availability.start_at.hour != availability.start_at.hour
                availability.start_at = dst_correction(initial_event.availability.start_at, availability.start_at)
                availability.end_at = dst_correction(initial_event.availability.end_at, availability.end_at)
                availability.save!
              end
            end
          rescue ActiveRecord::RecordNotFound
            failed_ids.push recurrent_event_id
          end
        end
      end

      if failed_ids.size > 0
        puts "WARNING: The events with IDs #{failed_ids} were not found.\n These were initial events of a recurrence.\n\n You may have to correct the following events manually (IDs): "
        puts "#{Event.where(recurrence_id: failed_ids).map(&:id)}"
      end
    end

    desc 'reset slug in events categories'
    task categories_slugs: :environment do
      Category.all.each do |cat|
        `curl -XPOST http://#{ENV["ELASTICSEARCH_HOST"]}:9200/stats/event/_update_by_query?conflicts=proceed&refresh&wait_for_completion -d '
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
      end
    end
  end
end

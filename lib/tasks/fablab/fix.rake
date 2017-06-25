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
  end
end

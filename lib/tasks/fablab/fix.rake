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
  end
end

class SingleizeEventCategories < ActiveRecord::Migration
  def up
    execute 'UPDATE events AS e
             SET category_id = ec.category_id
             FROM events_categories AS ec
             WHERE e.id = ec.event_id;'
  end

  def down
    execute 'INSERT INTO events_categories
             (event_id, category_id, created_at, updated_at)
             SELECT id, category_id, now(), now()
             FROM events;'

    execute 'UPDATE events
             SET category_id = NULL;'
  end
end

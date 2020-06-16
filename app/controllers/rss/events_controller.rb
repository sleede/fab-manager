# frozen_string_literal: true

# RSS feed about 10 last events
class Rss::EventsController < Rss::RssController

  def index
    @events = Event.includes(:event_image, :event_files, :availability, :category)
                   .where('availabilities.start_at >= ?', DateTime.current)
                   .order('availabilities.start_at ASC').references(:availabilities).limit(10)
    @fab_name = Setting.get('fablab_name')
  end
end

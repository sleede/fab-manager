class Rss::EventsController < Rss::RssController

  def index
    @events = Event.includes(:event_image, :event_files, :availability, :category)
                  .where('availabilities.start_at >= ?', Time.now)
                  .order('availabilities.start_at ASC').references(:availabilities).limit(10)
    @fab_name = Setting.find_by(name: 'fablab_name').value
  end
end

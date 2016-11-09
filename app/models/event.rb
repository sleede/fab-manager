class Event < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  has_one :event_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :event_image, allow_destroy: true
  has_many :event_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :event_files, allow_destroy: true, reject_if: :all_blank
  belongs_to :category
  validates :category, presence: true
  has_many :reservations, as: :reservable, dependent: :destroy
  has_and_belongs_to_many :event_themes, join_table: :events_event_themes, dependent: :destroy

  has_many :event_price_categories
  has_many :price_categories, through: :event_price_categories
  accepts_nested_attributes_for :event_price_categories, allow_destroy: false

  belongs_to :age_range

  belongs_to :availability, dependent: :destroy
  accepts_nested_attributes_for :availability

  attr_accessor :recurrence, :recurrence_end_at

  after_create :event_recurrence
  before_save :update_nb_free_places
  # update event updated_at for index cache
  after_save -> { self.touch }

  def name
    title
  end

  def themes
    self.event_themes
  end

  def recurrence_events
    Event.includes(:availability).where('events.recurrence_id = ? AND events.id != ? AND availabilities.start_at >= ?', recurrence_id, id, Time.now).references(:availabilities)
  end

  def safe_destroy
    reservations = Reservation.where(reservable_type: 'Event', reservable_id: id)
    if reservations.size == 0
      destroy
    else
      false
    end
  end

  ##
  # @deprecated
  # <b>DEPRECATED:</b> Please use <tt>event_price_categories</tt> instead.
  # This method is for backward compatibility only, do not use in new code
  def reduced_amount
    if ActiveRecord::Base.connection.column_exists?(:events, :reduced_amount)
      read_attribute(:reduced_amount)
    else
      pc = PriceCategory.find_by(name: I18n.t('price_category.reduced_fare'))
      reduced_fare = event_price_categories.where(price_category: pc).first
      if reduced_fare.nil?
        nil
      else
        reduced_fare.amount
      end
    end
  end

  # def reservations
  #   Reservation.where(reservable: self)
  # end

  private
  def event_recurrence
    if recurrence.present? and recurrence != 'none'
      case recurrence
      when 'day'
        on = nil
      when 'week'
        on = availability.start_at.wday
      when 'month'
        on = availability.start_at.day
      when 'year'
        on = [availability.start_at.month, availability.start_at.day]
      else
      end
      r = Recurrence.new(every: recurrence, on: on, starts: availability.start_at+1.day, until: recurrence_end_at)
      r.events.each do |date|
        days_diff = availability.end_at.day - availability.start_at.day
        start_at = DateTime.new(date.year, date.month, date.day, availability.start_at.hour, availability.start_at.min, availability.start_at.sec, availability.start_at.zone)
        end_date = date + days_diff.days
        end_at = DateTime.new(end_date.year, end_date.month, end_date.day, availability.end_at.hour, availability.end_at.min, availability.end_at.sec, availability.end_at.zone)
        if event_image
          ei = EventImage.new(attachment: event_image.attachment)
        end
        efs = event_files.map do |f|
          EventFile.new(attachment: f.attachment)
        end
        event_price_cats = []
        event_price_categories.each do |epc|
          event_price_cats.push(EventPriceCategory.new(price_category_id: epc.price_category_id, amount: epc.amount))
        end
        event = Event.new({
          recurrence: 'none',
          title: title,
          description: description,
          event_image: ei,
          event_files: efs,
          availability: Availability.new(start_at: start_at, end_at: end_at, available_type: 'event'),
          availability_id: nil,
          category_id: category_id,
          age_range_id: age_range_id,
          event_themes: event_themes,
          amount: amount,
          event_price_categories: event_price_cats,
          nb_total_places: nb_total_places,
          recurrence_id: id
        })
        event.save
      end
      update_columns(recurrence_id: id)
    end
  end

  def update_nb_free_places
    if nb_total_places.nil?
      self.nb_free_places = nil
    else
      reserved_places = reservations.map(&:total_booked_seats).inject(0){|sum, t| sum + t }
      self.nb_free_places = (nb_total_places - reserved_places)
    end
  end
end

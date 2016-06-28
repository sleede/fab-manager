class Event < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  has_one :event_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :event_image, allow_destroy: true
  has_many :event_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :event_files, allow_destroy: true, reject_if: :all_blank
  has_and_belongs_to_many :categories, join_table: :events_categories
  validates :categories, presence: true
  has_many :reservations, as: :reservable, dependent: :destroy

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
        event = Event.new({
          recurrence: 'none',
          title: title,
          description: description,
          event_image: ei,
          event_files: efs,
          availability: Availability.new(start_at: start_at, end_at: end_at, available_type: 'event'),
          availability_id: nil,
          category_ids: category_ids,
          amount: amount,
          reduced_amount: reduced_amount,
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
      reserved_places = reservations.map{|r| r.nb_reserve_places + r.nb_reserve_reduced_places}.inject(0){|sum, t| sum + t }
      self.nb_free_places = (nb_total_places - reserved_places)
    end
  end
end

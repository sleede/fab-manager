# frozen_string_literal: true

# Event is an happening organized by the Fablab about a general topic, which does not involve Machines or trainings member's skills.
class Event < ApplicationRecord
  include NotificationAttachedObject
  include ApplicationHelper

  has_one :event_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :event_image, allow_destroy: true

  has_many :event_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :event_files, allow_destroy: true, reject_if: :all_blank

  belongs_to :category
  validates :category, presence: true

  has_many :reservations, as: :reservable, dependent: :destroy

  has_many :events_event_themes, dependent: :destroy
  has_many :event_themes, through: :events_event_themes

  has_many :event_price_categories, dependent: :destroy
  has_many :price_categories, through: :event_price_categories
  accepts_nested_attributes_for :event_price_categories, allow_destroy: true

  belongs_to :age_range

  belongs_to :availability, dependent: :destroy
  accepts_nested_attributes_for :availability

  has_one :advanced_accounting, as: :accountable, dependent: :destroy
  accepts_nested_attributes_for :advanced_accounting, allow_destroy: true

  has_many :cart_item_event_reservations, class_name: 'CartItem::EventReservation', dependent: :destroy

  attr_accessor :recurrence, :recurrence_end_at

  before_save :update_nb_free_places
  after_create :event_recurrence

  # update event updated_at for index cache
  after_save -> { touch } # rubocop:disable Rails/SkipsModelValidations

  def name
    title
  end

  def themes
    event_themes
  end

  def recurrence_events
    Event.includes(:availability)
         .where('events.recurrence_id = ? AND events.id != ? AND availabilities.start_at >= ?', recurrence_id, id, Time.current)
         .references(:availabilities)
  end

  def destroyable?
    Reservation.where(reservable_type: 'Event', reservable_id: id).count.zero?
  end

  def soft_destroy!
    update(deleted_at: Time.current)
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

  def update_nb_free_places
    if nb_total_places.nil?
      self.nb_free_places = nil
    else
      reserved_places = reservations.joins(:slots_reservations)
                                    .where('slots_reservations.canceled_at': nil)
                                    .map(&:total_booked_seats)
                                    .inject(0) { |sum, t| sum + t }
      self.nb_free_places = (nb_total_places - reserved_places)
    end
  end

  def all_day?
    availability.start_at.hour.zero?
  end

  private

  def event_recurrence
    return unless recurrence.present? && recurrence != 'none'

    on = case recurrence
         when 'week'
           availability.start_at.wday
         when 'month'
           availability.start_at.day
         when 'year'
           [availability.start_at.month, availability.start_at.day]
         else
           nil
         end

    r = Recurrence.new(every: recurrence, on: on, starts: availability.start_at + 1.day, until: recurrence_end_at)
    r.events.each do |date|
      Event::CreateEventService.create_occurence(self, date)
    end
    update(recurrence_id: id)
  end
end

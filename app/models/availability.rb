# frozen_string_literal: true

# Availability stores time slots that are available to reservation for an associated reservable
# Eg. a 3D printer will be reservable on thursday from 9 to 11 pm
# Availabilities may be subdivided into Slots (of 1h), for some types of reservables (eg. Machine)
class Availability < ApplicationRecord
  # elastic initialisations
  include Elasticsearch::Model
  index_name 'fablab'
  document_type 'availabilities'

  has_many :machines_availabilities, dependent: :destroy
  has_many :machines, through: :machines_availabilities
  accepts_nested_attributes_for :machines, allow_destroy: true

  has_many :trainings_availabilities, dependent: :destroy
  has_many :trainings, through: :trainings_availabilities

  has_many :spaces_availabilities, dependent: :destroy
  has_many :spaces, through: :spaces_availabilities

  has_many :slots, dependent: :destroy
  has_many :slots_reservations, through: :slots
  has_many :reservations, through: :slots

  has_one :event, dependent: :destroy

  has_many :availability_tags, dependent: :destroy
  has_many :tags, through: :availability_tags
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_many :plans_availabilities, dependent: :destroy
  has_many :plans, through: :plans_availabilities
  accepts_nested_attributes_for :plans, allow_destroy: true

  scope :machines, -> { where(available_type: 'machines') }
  scope :trainings, -> { includes(:trainings).where(available_type: 'training') }
  scope :spaces, -> { includes(:spaces).where(available_type: 'space') }

  validates :start_at, :end_at, presence: true
  validate :length_must_be_slot_multiple, unless: proc { end_at.blank? or start_at.blank? }
  validate :should_be_associated

  # cache
  after_update :refresh_places_cache

  ## elastic callbacks
  after_save { AvailabilityIndexerWorker.perform_async(:index, id) }
  after_destroy { AvailabilityIndexerWorker.perform_async(:delete, id) }

  # elastic mapping
  settings index: { number_of_replicas: 0 } do
    mappings dynamic: 'true' do
      indexes 'available_type', analyzer: 'simple'
      indexes 'subType', index: 'not_analyzed'
    end
  end

  def safe_destroy
    case available_type
    when 'machines'
      reservations = find_reservations('Machine', machine_ids)
    when 'training'
      reservations = find_reservations('Training', training_ids)
    when 'space'
      reservations = find_reservations('Space', space_ids)
    when 'event'
      reservations = find_reservations('Event', [event&.id])
    else
      Rails.logger.warn "[safe_destroy] Availability with unknown type #{available_type}"
      reservations = []
    end
    if reservations.size.zero?
      # this update may not call any rails callbacks, that's why we use direct SQL update
      update_column(:destroying, true) # rubocop:disable Rails/SkipsModelValidations
      destroy
    else
      false
    end
  end

  # @param reservable_type [String]
  # @param reservable_ids [Array<Integer>]
  def find_reservations(reservable_type, reservable_ids)
    Reservation.where(reservable_type: reservable_type, reservable_id: reservable_ids)
               .joins(:slots)
               .where(slots: { availability_id: id })
  end

  ## compute the total number of places over the whole space availability
  def available_space_places
    return unless available_type == 'space'

    duration = slot_duration || Setting.get('slot_duration').to_i
    ((end_at - start_at) / duration.minutes).to_i * nb_total_places
  end

  def title(filter = {})
    case available_type
    when 'machines'
      return machines.to_ary.delete_if { |m| filter[:machine_ids].exclude?(m.id) }.map(&:name).join(' - ') if filter[:machine_ids]

      machines.map(&:name).join(' - ')
    when 'event'
      event.name
    when 'training'
      trainings.map(&:name).join(' - ')
    when 'space'
      spaces.map(&:name).join(' - ')
    else
      Rails.logger.warn "[title] Availability with unknown type #{available_type}"
      '???'
    end
  end

  # @return [Array<Integer>]
  def available_ids
    case available_type
    when 'training'
      training_ids
    when 'machines'
      machine_ids
    when 'event'
      [event&.id]
    when 'space'
      space_ids
    else
      []
    end
  end

  # check if the reservations are complete?
  # if a nb_total_places hasn't been defined, then places are unlimited
  # @return [Boolean]
  def full?
    return false if nb_total_places.blank? && available_type != 'machines'

    if available_type == 'event'
      event.nb_free_places.zero?
    else
      slots.map(&:full?).reduce(:&)
    end
  end

  # @return [Array<Integer>] Collection of User's IDs
  def reserved_users
    slots.map(&:reserved_users).flatten
  end

  # @param user_id [Integer]
  # @return [Boolean]
  def reserved_by?(user_id)
    reserved_users.include?(user_id)
  end

  def reserved?
    slots.map(&:reserved?).reduce(:&)
  end

  # check availability don't have any reservation
  def empty?
    slots.map(&:empty?).reduce(:&)
  end

  def available_places_per_slot(reservable = nil)
    case available_type
    when 'training'
      nb_total_places || reservable&.nb_total_places || trainings.map(&:nb_total_places).max
    when 'event'
      event.nb_total_places
    when 'space'
      nb_total_places || reservable&.default_places || spaces.map(&:default_places).max
    when 'machines'
      reservable.nil? ? machines.count : 1
    else
      raise TypeError, "unknown available type #{available_type} for availability #{id}"
    end
  end

  # the resulting JSON will be indexed in ElasticSearch, as /fablab/availabilities
  def as_indexed_json
    json = JSON.parse(to_json)
    json['hours_duration'] = (end_at - start_at) / (60 * 60)
    json['subType'] = case available_type
                      when 'machines'
                        machines_availabilities.map { |ma| ma.machine.friendly_id }
                      when 'training'
                        trainings_availabilities.map { |ta| ta.training.friendly_id }
                      when 'event'
                        [event.category.friendly_id]
                      when 'space'
                        spaces_availabilities.map { |sa| sa.space.friendly_id }
                      else
                        []
                      end
    json['bookable_hours'] = json['hours_duration'] * json['subType'].length
    json['date'] = start_at.to_date
    json.to_json
  end

  private

  def length_must_be_slot_multiple
    return unless available_type == 'machines' || available_type == 'space'

    duration = slot_duration || Setting.get('slot_duration').to_i
    return unless end_at < (start_at + duration.minutes)

    errors.add(:end_at, I18n.t('availabilities.length_must_be_slot_multiple', **{ MIN: duration }))
  end

  def should_be_associated
    return unless available_type == 'machines' && machine_ids.count.zero?

    errors.add(:machine_ids, I18n.t('availabilities.must_be_associated_with_at_least_1_machine'))
  end

  def refresh_places_cache
    slots.each do |slot|
      Slots::PlacesCacheService.refresh(slot)
    end
  end
end

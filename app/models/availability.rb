class Availability < ActiveRecord::Base

  # elastic initialisations
  include Elasticsearch::Model
  index_name 'fablab'
  document_type 'availabilities'

  has_many :machines_availabilities, dependent: :destroy
  has_many :machines, through: :machines_availabilities
  accepts_nested_attributes_for :machines, allow_destroy: true

  has_many :trainings_availabilities, dependent: :destroy
  has_many :trainings, through: :trainings_availabilities

  has_many :slots
  has_many :reservations, through: :slots

  has_one :event

  has_many :availability_tags, dependent: :destroy
  has_many :tags, through: :availability_tags
  accepts_nested_attributes_for :tags, allow_destroy: true

  scope :machines, -> { where(available_type: 'machines') }
  scope :trainings, -> { includes(:trainings).where(available_type: 'training') }

  attr_accessor :is_reserved, :slot_id, :can_modify

  validates :start_at, :end_at, presence: true
  validate :length_must_be_1h_minimum, unless: proc { end_at.blank? or start_at.blank? }
  validate :should_be_associated

  ## elastic callbacks
  after_save { AvailabilityIndexerWorker.perform_async(:index, self.id) }
  after_destroy { AvailabilityIndexerWorker.perform_async(:delete, self.id) }

  # elastic mapping
  settings do
    mappings dynamic: 'true' do
      indexes 'available_type', analyzer: 'simple'
      indexes 'subType', index: 'not_analyzed'
    end
  end

  def safe_destroy
    if available_type == 'machines'
      reservations = Reservation.where(reservable_type: 'Machine', reservable_id: machine_ids).joins(:slots).where('slots.availability_id = ?', id)
    else
      reservations = Reservation.where(reservable_type: 'Training', reservable_id: training_ids).joins(:slots).where('slots.availability_id = ?', id)
    end
    if reservations.size == 0
      # this update may not call any rails callbacks, that's why we use direct SQL update
      update_column(:destroying, true)
      destroy
    else
      false
    end
  end

  def title(filter = {})
    if available_type == 'machines'
      if filter[:machine_ids]
        return machines.to_ary.delete_if {|m| !filter[:machine_ids].include?(m.id)}.map(&:name).join(' - ')
      end
      return machines.map(&:name).join(' - ')
    elsif available_type == 'event'
      event.name
    else
      trainings.map(&:name).join(' - ')
    end
  end

  # return training reservations is complete?
  # if haven't defined a nb_total_places, places are unlimited
  def is_completed
    return false if nb_total_places.blank?
    if available_type == 'training'
      nb_total_places <= slots.to_a.select {|s| s.canceled_at == nil }.size
    elsif available_type == 'event'
      event.nb_free_places == 0
    end
  end

  # TODO: refactoring this function for avoid N+1 query
  def nb_total_places
    if available_type == 'training'
      if read_attribute(:nb_total_places).present?
        read_attribute(:nb_total_places)
      else
        trainings.first.nb_total_places unless trainings.empty?
      end
    elsif available_type == 'event'
      event.nb_total_places
    end
  end


  def as_indexed_json
    json = JSON.parse(to_json)
    json['hours_duration'] = (end_at - start_at) / (60 * 60)
    if available_type == 'machines'
      json['subType'] = machines_availabilities.map{|ma| ma.machine.friendly_id}
    elsif available_type == 'training'
      json['subType'] = trainings_availabilities.map{|ta| ta.training.friendly_id}
    elsif available_type == 'event'
      json['subType'] = [event.category.friendly_id]
    end
    json['bookable_hours'] = json['hours_duration'] * json['subType'].length
    json['date'] = start_at.to_date
    json.to_json
  end

  private
  def length_must_be_1h_minimum
    if end_at < (start_at + 1.hour)
      errors.add(:end_at, I18n.t('availabilities.must_be_at_least_1_hour_after_the_start_date'))
    end
  end

  def should_be_associated
    if available_type == 'machines' and machine_ids.count == 0
      errors.add(:machine_ids, I18n.t('availabilities.must_be_associated_with_at_least_1_machine'))
    end
  end

end

class Availability < ActiveRecord::Base
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
  scope :trainings, -> { where(available_type: 'training') }

  attr_accessor :is_reserved, :slot_id, :can_modify

  validates :start_at, :end_at, presence: true
  validate :length_must_be_1h_minimum, unless: proc { end_at.blank? or start_at.blank? }
  validate :should_be_associated

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

  def title
    if available_type == 'machines'
      machines.map(&:name).join(' - ')
    else
      trainings.map(&:name).join(' - ')
    end
  end

  # return training reservations is complete?
  # if haven't defined a nb_total_places, places are unlimited
  def is_completed
    return false if nb_total_places.blank?
    nb_total_places <= slots.where(canceled_at: nil).size
  end

  def nb_total_places
    if read_attribute(:nb_total_places).present?
      read_attribute(:nb_total_places)
    else
      trainings.first.nb_total_places unless trainings.empty?
    end
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

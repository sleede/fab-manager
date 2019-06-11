# frozen_string_literal: true

# Provides helper methods checking reservation status of any availabilities
class Availabilities::StatusService
  def initialize(current_user_role)
    @current_user_role = current_user_role
    @show_name = (@current_user_role == 'admin' || Setting.find_by(name: 'display_name_enable').value == 'true')
  end

  # check that the provided machine slot is reserved or not and modify it accordingly
  def machine_reserved_status(slot, reservations, user)
    statistic_profile_id = user&.statistic_profile&.id
    reservations.each do |r|
      r.slots.each do |s|
        next unless slot.machine.id == r.reservable_id

        next unless s.start_at == slot.start_at && s.canceled_at.nil?

        slot.id = s.id
        slot.is_reserved = true
        slot.title = "#{slot.machine.name} - #{@show_name ? r.user.profile.full_name : I18n.t('availabilities.not_available')}"
        slot.can_modify = true if @current_user_role == 'admin'
        slot.reservations.push r

        next unless r.statistic_profile_id == statistic_profile_id

        slot.title = "#{slot.machine.name} - #{I18n.t('availabilities.i_ve_reserved')}"
        slot.can_modify = true
        slot.is_reserved_by_current_user = true
      end
    end
    slot
  end

  # check that the provided space slot is reserved or not and modify it accordingly
  def space_reserved_status(slot, reservations, user)
    statistic_profile_id = user&.statistic_profile&.id
    reservations.each do |r|
      r.slots.each do |s|
        next unless slot.space.id == r.reservable_id

        next unless s.start_at == slot.start_at && s.canceled_at.nil?

        slot.can_modify = true if @current_user_role == 'admin'
        slot.reservations.push r

        next unless r.statistic_profile_id == statistic_profile_id

        slot.id = s.id
        slot.title = I18n.t('availabilities.i_ve_reserved')
        slot.can_modify = true
        slot.is_reserved = true
      end
    end
    slot
  end

  # check that the provided availability (training or event) is reserved or not and modify it accordingly
  def training_event_reserved_status(availability, reservations, user)
    statistic_profile_id = user&.statistic_profile&.id
    reservations.each do |r|
      r.slots.each do |s|
        next unless (
          (availability.available_type == 'training' && availability.trainings.first.id == r.reservable_id) ||
          (availability.available_type == 'event' && availability.event.id == r.reservable_id)
        ) && s.start_at == availability.start_at && s.canceled_at.nil?

        availability.slot_id = s.id
        if r.statistic_profile_id == statistic_profile_id
          availability.is_reserved = true
          availability.can_modify = true
        end
      end
    end
    availability
  end

  # check that the provided ability is reserved by the given user
  def reserved_availability?(availability, user)
    if user
      reserved_slots = []
      availability.slots.each do |s|
        reserved_slots << s if s.canceled_at.nil?
      end
      reserved_slots.map(&:reservations).flatten.map(&:user_id).include? user.id
    else
      false
    end
  end
end

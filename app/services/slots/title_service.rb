# frozen_string_literal: true

# Build the title of the provided slot
class Slots::TitleService
  def initialize(operator_role, user)
    @user = user
    @show_name = (%w[admin manager].include?(operator_role) || (operator_role && Setting.get('display_name_enable')))
  end

  # @param slot [Slot]
  # @param reservables [Array<Machine, Space, Training, Event>]
  def call(slot, reservables = nil)
    reservables = all_reservables(slot) if reservables.nil?
    is_reserved = slot.reserved?
    is_reserved_by_user = slot.reserved_by?(@user&.id, reservables)

    name = reservables.map(&:name).join(', ')
    if !is_reserved && !is_reserved_by_user
      name
    elsif is_reserved && !is_reserved_by_user
      "#{name} #{@show_name ? "- #{slot_users_names(slot, reservables)}" : ''}"
    else
      "#{name} - #{I18n.t('availabilities.i_ve_reserved')}"
    end
  end

  private

  # @param slot [Slot]
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @return [String]
  def slot_users_names(slot, reservables)
    user_ids = slot.reserved_users(reservables)
    User.where(id: user_ids).includes(:profile)
        .map { |u| u&.profile&.full_name || I18n.t('availabilities.deleted_user') }
        .join(', ')
  end

  # @param slot [Slot]
  def all_reservables(slot)
    slot.places.pluck('reservable_type', 'reservable_id').map { |r| r[0].classify.constantize.find(r[1]) }
  end
end

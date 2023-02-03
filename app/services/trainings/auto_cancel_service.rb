# frozen_string_literal: true

# Business logic around trainings
module Trainings; end

# Automatically cancel trainings without enough reservation
class Trainings::AutoCancelService
  class << self
    # @param training [Training]
    def auto_cancel_reservations(training)
      return unless training.auto_cancel

      training.availabilities
              .includes(slots: :slots_reservations)
              .where(availabilities: { lock: false })
              .where('availabilities.start_at >= ? AND availabilities.start_at <= ?',
                     DateTime.current,
                     DateTime.current + training.auto_cancel_deadline.hours)
              .find_each do |availability|
        next if availability.reservations.count >= training.auto_cancel_threshold

        auto_refund = Setting.get('wallet_module')

        NotificationCenter.call type: 'notify_admin_training_auto_cancelled',
                                receiver: User.admins_and_managers,
                                attached_object: availability,
                                meta_data: { auto_refund: auto_refund }

        availability.update(lock: true)
        availability.slots_reservations.find_each do |sr|
          NotificationCenter.call type: 'notify_member_training_auto_cancelled',
                                  receiver: sr.reservation.user,
                                  attached_object: sr,
                                  meta_data: { auto_refund: auto_refund }

          sr.update(canceled_at: DateTime.current)
          refund_after_cancel(sr.reservation) if auto_refund
        end
      end
    end

    # update the given training, depending on the provided settings
    # @param training [Training]
    # @param auto_cancel [Setting,NilClass]
    # @param threshold [Setting,NilClass]
    # @param deadline [Setting,NilClass]
    def update_auto_cancel(training, auto_cancel, threshold, deadline)
      previous_auto_cancel = auto_cancel.nil? ? Setting.find_by(name: 'trainings_auto_cancel').value : auto_cancel.previous_value
      previous_threshold = threshold.nil? ? Setting.find_by(name: 'trainings_auto_cancel_threshold').value : threshold.previous_value
      previous_deadline = deadline.nil? ? Setting.find_by(name: 'trainings_auto_cancel_deadline').value : deadline.previous_value
      is_default = training.auto_cancel.to_s == previous_auto_cancel.to_s &&
                   training.auto_cancel_threshold.to_s == previous_threshold.to_s &&
                   training.auto_cancel_deadline.to_s == previous_deadline.to_s

      return unless is_default

      # update parameters if the given training is default
      params = {}
      params[:auto_cancel] = auto_cancel.value unless auto_cancel.nil?
      params[:auto_cancel_threshold] = threshold.value unless threshold.nil?
      params[:auto_cancel_deadline] = deadline.value unless deadline.nil?
      training.update(params)
    end

    # @param training [Training]
    # @return [Boolean]
    def override_settings?(training)
      training.auto_cancel.to_s != Setting.find_by(name: 'trainings_auto_cancel')&.value.to_s ||
        training.auto_cancel_threshold.to_s != Setting.find_by(name: 'trainings_auto_cancel_threshold')&.value.to_s ||
        training.auto_cancel_deadline.to_s != Setting.find_by(name: 'trainings_auto_cancel_deadline')&.value.to_s
    end

    private

    # @param reservation [Reservation]
    def refund_after_cancel(reservation)
      invoice_item = reservation.invoice_items.joins(:invoice).where(invoices: { type: nil }).first
      amount = (invoice_item&.amount_after_coupon || 0) / 100.00
      return if amount.zero?

      service = WalletService.new(user: reservation.user, wallet: reservation.user.wallet)
      transaction = service.credit(amount)
      service.create_avoir(transaction, DateTime.current, I18n.t('trainings.refund_for_auto_cancel')) if transaction
    end
  end
end

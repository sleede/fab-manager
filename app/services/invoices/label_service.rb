# frozen_string_literal: true

# module definition
module Invoices; end

# Build a label for the given invoice
class Invoices::LabelService
  class << self
    # @param invoice [Invoice]
    # @return [String, nil]
    def build(invoice)
      username = Invoices::RecipientService.name(invoice)
      if invoice.is_a?(Avoir)
        avoir_label(invoice)
      else
        case invoice.main_item&.object_type
        when 'Reservation'
          reservation_invoice_label(invoice, username)
        when 'Subscription'
          subscription_label(invoice.main_item.object, username)
        when 'OfferDay'
          offer_day_label(invoice.main_item.object, username)
        when 'Error'
          invoice.main_item&.object_id&.zero? ? I18n.t('invoices.error_invoice') : invoice.main_item&.description
        when 'StatisticProfilePrepaidPack'
          I18n.t('invoices.prepaid_pack')
        when 'OrderItem'
          I18n.t('invoices.order')
        else
          Rails.logger.error "specified main_item.object_type type (#{invoice.main_item&.object_type}) is unknown"
          nil
        end
      end
    end

    private

    # @param invoice [Invoice]
    # @return [String]
    def avoir_label(invoice)
      return I18n.t('invoices.wallet_credit') if invoice.main_item&.object_type == WalletTransaction.name

      I18n.t('invoices.cancellation_of_invoice_REF', **{ REF: invoice.invoice.reference })
    end

    # @param invoice [Invoice]
    # @param username [String]
    # @return [String]
    def reservation_invoice_label(invoice, username)
      label = I18n.t('invoices.reservation_of_USER_on_DATE_at_TIME',
                     **{ USER: username,
                         DATE: I18n.l(invoice.main_item.object.slots[0].start_at.to_date),
                         TIME: I18n.l(invoice.main_item.object.slots[0].start_at, format: :hour_minute) })
      invoice.invoice_items.each do |item|
        next unless item.object_type == Subscription.name

        subscription = item.object
        cancellation = invoice.is_a?(Avoir) ? "#{I18n.t('invoices.cancellation')} - " : ''
        label = "\n- #{label}\n- #{cancellation + subscription_label(subscription, username)}"
        break
      end
      label
    end

    # @param subscription [Subscription]
    # @param username [String]
    # @return [String]
    def subscription_label(subscription, username)
      subscription_start_at = subscription.expired_at - subscription.plan.duration
      duration_verbose = I18n.t("duration.#{subscription.plan.interval}", **{ count: subscription.plan.interval_count })
      I18n.t('invoices.subscription_of_NAME_for_DURATION_starting_from_DATE',
             **{ NAME: username,
                 DURATION: duration_verbose,
                 DATE: I18n.l(subscription_start_at.to_date) })
    end

    # @param offer_day [OfferDay]
    # @param username [String]
    # @return [String]
    def offer_day_label(offer_day, username)
      I18n.t('invoices.subscription_of_NAME_extended_starting_from_STARTDATE_until_ENDDATE',
             **{ NAME: username,
                 STARTDATE: I18n.l(offer_day.start_at.to_date),
                 ENDDATE: I18n.l(offer_day.end_at.to_date) })
    end
  end
end

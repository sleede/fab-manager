# frozen_string_literal: true

# module definition
module Invoices; end

# Build a label for the given invoice item
class Invoices::ItemLabelService
  class << self
    # @param invoice [Invoice]
    # @param item [InvoiceItem]
    # @return [String]
    def build(invoice, item)
      details = invoice.is_a?(Avoir) ? "#{I18n.t('invoices.cancellation')} - " : ''

      if item.object_type == Subscription.name
        "#{details}#{build_subscription_label(invoice, item)}"
      elsif item.object_type == Reservation.name
        "#{details}#{build_reservation_label(invoice, item)}"
      else
        "#{details}#{item.description}"
      end
    end

    private

    # @param invoice [Invoice]
    # @param item [InvoiceItem]
    # @return [String]
    def build_subscription_label(invoice, item)
      subscription = item.object
      label = if invoice.main_item&.object_type == 'OfferDay'
                I18n.t('invoices.subscription_extended_for_free_from_START_to_END',
                       **{ START: I18n.l(invoice.main_item&.object&.start_at&.to_date),
                           END: I18n.l(invoice.main_item&.object&.end_at&.to_date) })
              else
                subscription_end_at = subscription.expiration_date
                subscription_start_at = subscription_end_at - subscription.plan.duration
                I18n.t('invoices.subscription_NAME_from_START_to_END',
                       **{ NAME: item.description,
                           START: I18n.l(subscription_start_at.to_date),
                           END: I18n.l(subscription_end_at.to_date) })
              end
      unless invoice.payment_schedule_item.nil?
        dues = invoice.payment_schedule_item.payment_schedule.payment_schedule_items.order(:due_date)
        label += "\n #{I18n.t('invoices.from_payment_schedule',
                              **{ NUMBER: dues.index(invoice.payment_schedule_item) + 1,
                                  TOTAL: dues.count,
                                  DATE: I18n.l(invoice.payment_schedule_item.due_date.to_date),
                                  SCHEDULE: invoice.payment_schedule_item.payment_schedule.reference })}"
      end
      label
    end

    # @param invoice [Invoice]
    # @param item [InvoiceItem]
    # @return [String]
    def build_reservation_label(invoice, item)
      case invoice.main_item&.object.try(:reservable_type)
        ### Machine reservation
      when 'Machine'
        I18n.t('invoices.machine_reservation_DESCRIPTION', **{ DESCRIPTION: item.description })
      when 'Space'
        I18n.t('invoices.space_reservation_DESCRIPTION', **{ DESCRIPTION: item.description })
        ### Training reservation
      when 'Training'
        I18n.t('invoices.training_reservation_DESCRIPTION', **{ DESCRIPTION: item.description })
        ### events reservation
      when 'Event'
        build_event_reservation_label(invoice, item)
      else
        item.description
      end
    end

    # @param invoice [Invoice]
    # @param item [InvoiceItem]
    # @return [String]
    def build_event_reservation_label(invoice, item)
      label = I18n.t('invoices.event_reservation_DESCRIPTION', **{ DESCRIPTION: item.description })
      # details of the number of tickets
      if invoice.main_item&.object&.nb_reserve_places&.positive?
        label += "\n  #{I18n.t('invoices.full_price_ticket', **{ count: invoice.main_item&.object&.nb_reserve_places })}"
      end
      invoice.main_item&.object&.tickets&.each do |t|
        label += "\n #{I18n.t('invoices.other_rate_ticket',
                              **{ count: t.booked,
                                  NAME: t.event_price_category.price_category.name })}"
      end
      label
    end
  end
end

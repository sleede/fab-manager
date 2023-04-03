# frozen_string_literal: true

# module definition
module Invoices; end

# Build a localized string detailing the payment mean for the given invoice
class Invoices::PaymentDetailsService
  class << self
    include ActionView::Helpers::NumberHelper

    # @param invoice [Invoice]
    # @param total [Float]
    # @return [String]
    def build(invoice, total)
      if invoice.is_a?(Avoir)
        build_avoir_details(invoice, total)
      else
        # subtract the wallet amount for this invoice from the total
        wallet_amount = wallet_amount(invoice)
        total -= wallet_amount unless wallet_amount.nil?
        return '' if wallet_amount.nil? && total.zero?

        # payment method
        payment_verbose = payment_mean(invoice, total, wallet_amount)

        payment_verbose += " #{I18n.t('invoices.on_DATE_at_TIME',
                                      **{ DATE: I18n.l(invoice.created_at.to_date),
                                          TIME: I18n.l(invoice.created_at, format: :hour_minute) })}"
        if total.positive? || wallet_amount.nil?
          payment_verbose += " #{I18n.t('invoices.for_an_amount_of_AMOUNT', **{ AMOUNT: number_to_currency(total) })}"
        end
        if invoice.wallet_amount
          payment_verbose += if total.positive?
                               " #{I18n.t('invoices.and')} #{I18n.t('invoices.by_wallet')} " \
                                 "#{I18n.t('invoices.for_an_amount_of_AMOUNT', **{ AMOUNT: number_to_currency(wallet_amount) })}"
                             else
                               " #{I18n.t('invoices.for_an_amount_of_AMOUNT', **{ AMOUNT: number_to_currency(wallet_amount) })}"
                             end
        end
        payment_verbose
      end
    end

    private

    # @param invoice [Invoice]
    # @return [Float,NilClass]
    def wallet_amount(invoice)
      return invoice.wallet_amount / 100.00 if invoice.wallet_amount

      nil
    end

    # @param invoice [Invoice]
    # @param total [Float]
    # @param wallet_amount [Float,NilClass]
    # @return [String]
    def payment_mean(invoice, total, wallet_amount)
      # if the invoice was 100% payed with the wallet ...
      return I18n.t('invoices.settlement_by_wallet') if total.zero? && !wallet_amount.nil?

      # else
      if invoice.paid_by_card?
        I18n.t('invoices.settlement_by_debit_card')
      else
        I18n.t('invoices.settlement_done_at_the_reception')
      end
    end

    # @param invoice [Invoice]
    # @param total [Float]
    # @return [String]
    def build_avoir_details(invoice, total)
      details = "#{I18n.t('invoices.refund_on_DATE', **{ DATE: I18n.l(invoice.avoir_date.to_date) })} "
      case invoice.payment_method
      when 'stripe'
        details += I18n.t('invoices.by_card_online_payment')
      when 'cheque'
        details += I18n.t('invoices.by_cheque')
      when 'transfer'
        details += I18n.t('invoices.by_transfer')
      when 'cash'
        details += I18n.t('invoices.by_cash')
      when 'wallet'
        details += I18n.t('invoices.by_wallet')
      when 'none'
        details = I18n.t('invoices.no_refund')
      else
        Rails.logger.error "specified refunding method (#{details}) is unknown"
      end
      "#{details} #{I18n.t('invoices.for_an_amount_of_AMOUNT', **{ AMOUNT: number_to_currency(total) })}"
    end
  end
end

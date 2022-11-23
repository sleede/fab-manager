# frozen_string_literal: true

# Generate a downloadable PDF file for the recorded invoice
class PDF::Invoice < Prawn::Document
  require 'stringio'
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  def initialize(invoice, subscription_expiration_date)
    super(margin: 70)

    # fonts
    opensans = Rails.root.join('vendor/assets/fonts/OpenSans-Regular.ttf').to_s
    opensans_bold = Rails.root.join('vendor/assets/fonts/OpenSans-Bold.ttf').to_s
    opensans_bolditalic = Rails.root.join('vendor/assets/fonts/OpenSans-BoldItalic.ttf').to_s
    opensans_italic = Rails.root.join('vendor/assets/fonts/OpenSans-Italic.ttf').to_s

    font_families.update(
      'Open-Sans' => {
        normal: { file: opensans, font: 'Open-Sans' },
        bold: { file: opensans_bold, font: 'Open-Sans-Bold' },
        italic: { file: opensans_italic, font: 'Open-Sans-Oblique' },
        bold_italic: { file: opensans_bolditalic, font: 'Open-Sans-BoldOblique' }
      }
    )

    # logo
    img_b64 = Setting.get('invoice_logo')
    begin
      image StringIO.new(Base64.decode64(img_b64)), fit: [415, 40]
    rescue StandardError => e
      Rails.logger.error "Unable to decode invoice logo from base64: #{e}"
    end
    move_down 20
    # the following line is a special comment to workaround RubyMine inspection problem
    # noinspection RubyScope
    font('Open-Sans', size: 10) do
      # general information
      if invoice.is_a?(Avoir)
        text I18n.t('invoices.refund_invoice_reference', REF: invoice.reference), leading: 3
      else
        text I18n.t('invoices.invoice_reference', REF: invoice.reference), leading: 3
      end
      text I18n.t('invoices.code', CODE: Setting.get('invoice_code-value')), leading: 3 if Setting.get('invoice_code-active')
      if invoice.main_item.object_type != WalletTransaction.name
        order_number = invoice.main_item.object_type == OrderItem.name ? invoice.main_item.object.order.reference : invoice.order_number
        text I18n.t('invoices.order_number', NUMBER: order_number), leading: 3
      end
      if invoice.is_a?(Avoir)
        text I18n.t('invoices.refund_invoice_issued_on_DATE', DATE: I18n.l(invoice.avoir_date.to_date))
      else
        text I18n.t('invoices.invoice_issued_on_DATE', DATE: I18n.l(invoice.created_at.to_date))
      end

      # user/organization's information
      name = Invoices::RecipientService.name(invoice)
      others = Invoices::RecipientService.organization_data(invoice)
      address = Invoices::RecipientService.address(invoice)

      text_box "<b>#{name}</b>\n#{invoice.invoicing_profile.email}\n#{address}\n#{others&.join("\n")}",
               at: [bounds.width - 180, bounds.top - 49],
               width: 180,
               align: :right,
               inline_format: true

      # object
      move_down 28
      text "#{I18n.t('invoices.object')} #{Invoices::LabelService.build(invoice)}"

      # details table of the invoice's elements
      move_down 20
      text I18n.t('invoices.order_summary'), leading: 4
      move_down 2
      data = [[I18n.t('invoices.details'), I18n.t('invoices.amount')]]

      total_calc = 0
      total_ht = 0
      total_vat = 0
      # going through invoice_items
      invoice.invoice_items.each do |item|
        price = item.amount.to_i / 100.00

        details = invoice.is_a?(Avoir) ? "#{I18n.t('invoices.cancellation')} - " : ''

        if item.object_type == Subscription.name
          subscription = item.object
          if invoice.main_item.object_type == 'OfferDay'
            details += I18n.t('invoices.subscription_extended_for_free_from_START_to_END',
                              START: I18n.l(invoice.main_item.object.start_at.to_date),
                              END: I18n.l(invoice.main_item.object.end_at.to_date))
          else
            subscription_end_at = case subscription_expiration_date
                                  when Time
                                    subscription_expiration_date
                                  when String
                                    DateTime.parse(subscription_expiration_date)
                                  else
                                    subscription.expiration_date
                                  end
            subscription_start_at = subscription_end_at - subscription.plan.duration
            details += I18n.t('invoices.subscription_NAME_from_START_to_END',
                              NAME: item.description,
                              START: I18n.l(subscription_start_at.to_date),
                              END: I18n.l(subscription_end_at.to_date))
          end

        elsif item.object_type == Reservation.name
          case invoice.main_item.object.try(:reservable_type)
            ### Machine reservation
          when 'Machine'
            details += I18n.t('invoices.machine_reservation_DESCRIPTION', DESCRIPTION: item.description)
          when 'Space'
            details += I18n.t('invoices.space_reservation_DESCRIPTION', DESCRIPTION: item.description)
          ### Training reservation
          when 'Training'
            details += I18n.t('invoices.training_reservation_DESCRIPTION', DESCRIPTION: item.description)
          ### events reservation
          when 'Event'
            details += I18n.t('invoices.event_reservation_DESCRIPTION', DESCRIPTION: item.description)
            # details of the number of tickets
            if invoice.main_item.object.nb_reserve_places.positive?
              details += "\n  #{I18n.t('invoices.full_price_ticket', count: invoice.main_item.object.nb_reserve_places)}"
            end
            invoice.main_item.object.tickets.each do |t|
              details += "\n #{I18n.t('invoices.other_rate_ticket',
                                      count: t.booked,
                                      NAME: t.event_price_category.price_category.name)}"
            end
          else
            details += item.description
          end
        else
          details += item.description
        end

        data += [[details, number_to_currency(price)]]
        total_calc += price
        total_ht += item.net_amount
        total_vat += item.vat
      end

      ## subtract the coupon, if any
      unless invoice.coupon_id.nil?
        cp = invoice.coupon
        coupon_service = CouponService.new
        total_without_coupon = coupon_service.invoice_total_no_coupon(invoice)
        discount = (total_without_coupon - invoice.total) / 100.00

        total_calc -= discount

        # discount textual description
        literal_discount = cp.percent_off
        literal_discount = number_to_currency(cp.amount_off / 100.00) if cp.type == 'amount_off'

        # add a row for the coupon
        data += [[_t('invoices.coupon_CODE_discount_of_DISCOUNT',
                     CODE: cp.code,
                     DISCOUNT: literal_discount,
                     TYPE: cp.type), number_to_currency(-discount)]]
      end

      # total verification
      total = invoice.total / 100.00
      Rails.logger.error "totals are NOT equals => expected: #{total}, computed: #{total_calc}" if total_calc != total

      # TVA
      vat_service = VatHistoryService.new
      vat_rate_group = vat_service.invoice_vat(invoice)
      if total_vat.zero?
        data += [[I18n.t('invoices.total_amount'), number_to_currency(total)]]
      else
        data += [[I18n.t('invoices.total_including_all_taxes'), number_to_currency(total)]]
        vat_rate_group.each do |_type, rate|
          data += [[I18n.t('invoices.including_VAT_RATE', RATE: rate[:vat_rate], AMOUNT: number_to_currency(rate[:amount] / 100.00)),
                    number_to_currency(rate[:total_vat] / 100.00)]]
        end
        data += [[I18n.t('invoices.including_total_excluding_taxes'), number_to_currency(total_ht / 100.00)]]
        data += [[I18n.t('invoices.including_amount_payed_on_ordering'), number_to_currency(total)]]

        # checking the round number
        rounded = (sprintf('%.2f', total_vat / 100.00).to_f + sprintf('%.2f', total_ht / 100.00).to_f).to_s
        if rounded != sprintf('%.2f', total_calc)
          Rails.logger.error 'rounding the numbers cause an invoice inconsistency. ' \
                             "Total expected: #{sprintf('%.2f', total_calc)}, total computed: #{rounded}"
        end
      end

      # display table
      table(data, header: true, column_widths: [400, 72], cell_style: { inline_format: true }) do
        row(0).font_style = :bold
        column(1).style align: :right

        if total_vat != 0
          # Total incl. taxes
          row(-1).style align: :right
          row(-1).background_color = 'E4E4E4'
          row(-1).font_style = :bold
          vat_rate_group.size.times do |i|
            # including VAT xx%
            row(-2 - i).style align: :right
            row(-2 - i).background_color = 'E4E4E4'
            row(-2 - i).font_style = :italic
          end
          # including total excl. taxes
          row(-3 - vat_rate_group.size + 1).style align: :right
          row(-3 - vat_rate_group.size + 1).background_color = 'E4E4E4'
          row(-3 - vat_rate_group.size + 1).font_style = :italic
          # including amount payed on ordering
          row(-4 - vat_rate_group.size + 1).style align: :right
          row(-4 - vat_rate_group.size + 1).background_color = 'E4E4E4'
          row(-4 - vat_rate_group.size + 1).font_style = :bold
        end
      end

      # optional description for refunds
      move_down 20
      text invoice.description if invoice.is_a?(Avoir) && invoice.description

      # payment details
      move_down 20
      if invoice.is_a?(Avoir)
        payment_verbose = "#{I18n.t('invoices.refund_on_DATE', DATE: I18n.l(invoice.avoir_date.to_date))} "
        case invoice.payment_method
        when 'stripe'
          payment_verbose += I18n.t('invoices.by_card_online_payment')
        when 'cheque'
          payment_verbose += I18n.t('invoices.by_cheque')
        when 'transfer'
          payment_verbose += I18n.t('invoices.by_transfer')
        when 'cash'
          payment_verbose += I18n.t('invoices.by_cash')
        when 'wallet'
          payment_verbose += I18n.t('invoices.by_wallet')
        when 'none'
          payment_verbose = I18n.t('invoices.no_refund')
        else
          Rails.logger.error "specified refunding method (#{payment_verbose}) is unknown"
        end
        payment_verbose += " #{I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(total))}"
      else
        # subtract the wallet amount for this invoice from the total
        if invoice.wallet_amount
          wallet_amount = invoice.wallet_amount / 100.00
          total -= wallet_amount
        else
          wallet_amount = nil
        end

        # payment method
        payment_verbose = if invoice.paid_by_card?
                            I18n.t('invoices.settlement_by_debit_card')
                          else
                            I18n.t('invoices.settlement_done_at_the_reception')
                          end

        # if the invoice was 100% payed with the wallet ...
        payment_verbose = I18n.t('invoices.settlement_by_wallet') if total.zero? && wallet_amount

        payment_verbose += " #{I18n.t('invoices.on_DATE_at_TIME',
                                      DATE: I18n.l(invoice.created_at.to_date),
                                      TIME: I18n.l(invoice.created_at, format: :hour_minute))}"
        if total.positive? || !invoice.wallet_amount
          payment_verbose += " #{I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(total))}"
        end
        if invoice.wallet_amount
          payment_verbose += if total.positive?
                               " #{I18n.t('invoices.and')} #{I18n.t('invoices.by_wallet')} " \
                                 "#{I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(wallet_amount))}"
                             else
                               " #{I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(wallet_amount))}"
                             end
        end
      end
      text payment_verbose

      # important information
      move_down 40
      txt = parse_html(Setting.get('invoice_text'))
      txt.each_line do |line|
        text line, style: :bold, inline_format: true
      end

      # address and legals information
      move_down 40
      txt = parse_html(Setting.get('invoice_legals'))
      txt.each_line do |line|
        text line, align: :right, leading: 4, inline_format: true
      end
    end

    # factice watermark
    return unless %w[staging test development].include?(invoice.environment)

    transparent(0.1) do
      rotate(45, origin: [0, 0]) do
        image Rails.root.join("app/pdfs/data/watermark-#{I18n.default_locale}.png"), at: [90, 150]
      end
    end
  end

  private

  def reservation_dates_verbose(slot)
    if slot.start_at.to_date == slot.end_at.to_date
      "- #{I18n.t('invoices.on_DATE_from_START_to_END',
                  DATE: I18n.l(slot.start_at.to_date),
                  START: I18n.l(slot.start_at, format: :hour_minute),
                  END: I18n.l(slot.end_at, format: :hour_minute))}\n"
    else
      "- #{I18n.t('invoices.from_STARTDATE_to_ENDDATE_from_STARTTIME_to_ENDTIME',
                  STARTDATE: I18n.l(slot.start_at.to_date),
                  ENDDATE: I18n.l(slot.start_at.to_date),
                  STARTTIME: I18n.l(slot.start_at, format: :hour_minute),
                  ENDTIME: I18n.l(slot.end_at, format: :hour_minute))}\n"
    end
  end

  ##
  # Remove every unsupported html tag from the given html text (like <p>, <span>, ...).
  # The supported tags are <b>, <u>, <i> and <br>.
  # @param html [String] single line html text
  # @return [String] multi line simplified html text
  ##
  def parse_html(html)
    ActionController::Base.helpers.sanitize(html, tags: %w[b u i br])
  end
end

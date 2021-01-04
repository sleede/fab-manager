# frozen_string_literal: true

# Generate a downloadable PDF file for the recorded payment schedule
class PDF::PaymentSchedule < Prawn::Document
  require 'stringio'
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  def initialize(payment_schedule)
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
    img_b64 = Setting.find_by(name: 'invoice_logo')
    begin
      image StringIO.new(Base64.decode64(img_b64.value)), fit: [415, 40]
    rescue StandardError => e
      puts "Unable to decode invoice logo from base64: #{e}"
    end
    move_down 20
    font('Open-Sans', size: 10) do
      # general information
      text I18n.t('payment_schedules.schedule_reference', REF: payment_schedule.reference), leading: 3
      text I18n.t('payment_schedules.code', CODE: Setting.get('invoice_code-value')), leading: 3 if Setting.get('invoice_code-active')
      text I18n.t('payment_schedules.order_number', NUMBER: payment_schedule.order_number), leading: 3
      text I18n.t('payment_schedules.schedule_issued_on_DATE', DATE: I18n.l(payment_schedule.created_at.to_date))

      # user/organization's information
      if payment_schedule.invoicing_profile&.organization
        name = payment_schedule.invoicing_profile.organization.name
        full_name = "#{name} (#{payment_schedule.invoicing_profile.full_name})"
      else
        name = payment_schedule.invoicing_profile.full_name
        full_name = name
      end

      address = if payment_schedule.invoicing_profile&.organization&.address
                  payment_schedule.invoicing_profile.organization.address.address
                elsif payment_schedule.invoicing_profile&.address
                  payment_schedule.invoicing_profile.address.address
                else
                  ''
                end

      text_box "<b>#{name}</b>\n#{payment_schedule.invoicing_profile.email}\n#{address}",
               at: [bounds.width - 130, bounds.top - 49],
               width: 130,
               align: :right,
               inline_format: true
      name = full_name

      # object
      move_down 25
      case payment_schedule.scheduled_type
      when 'Reservation'
        object = I18n.t('invoices.reservation_of_USER_on_DATE_at_TIME',
                        USER: name,
                        DATE: I18n.l(invoice.invoiced.slots[0].start_at.to_date),
                        TIME: I18n.l(invoice.invoiced.slots[0].start_at, format: :hour_minute))
        invoice.invoice_items.each do |item|
          next unless item.subscription_id

          subscription = Subscription.find item.subscription_id
          cancellation = invoice.is_a?(Avoir) ? I18n.t('invoices.cancellation') + ' - ' : ''
          object = "\n- #{object}\n- #{cancellation + subscription_verbose(subscription, name)}"
          break
        end
      when 'Subscription'
        object = subscription_verbose(payment_schedule.invoiced, name)
      else
        puts "ERROR : specified scheduled type (#{payment_schedule.scheduled_type}) is unknown"
      end
      text I18n.t('invoices.object') + ' ' + object

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

        details = invoice.is_a?(Avoir) ? I18n.t('invoices.cancellation') + ' - ' : ''

        if item.subscription_id ### Subscription
          subscription = Subscription.find item.subscription_id
          if invoice.invoiced_type == 'OfferDay'
            details += I18n.t('invoices.subscription_extended_for_free_from_START_to_END',
                              START: I18n.l(invoice.invoiced.start_at.to_date),
                              END: I18n.l(invoice.invoiced.end_at.to_date))
          else
            subscription_end_at = if subscription_expiration_date.is_a?(Time)
                                    subscription_expiration_date
                                  elsif subscription_expiration_date.is_a?(String)
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


        else ### Reservation
          case invoice.invoiced.try(:reservable_type)
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
            if invoice.invoiced.nb_reserve_places.positive?
              details += "\n  " + I18n.t('invoices.full_price_ticket', count: invoice.invoiced.nb_reserve_places)
            end
            invoice.invoiced.tickets.each do |t|
              details += "\n  " + I18n.t('invoices.other_rate_ticket',
                                         count: t.booked,
                                         NAME: t.event_price_category.price_category.name)
            end
          ### wallet credit
          when nil
            details = item.description

          ### Other cases (not expected)
          else
            details += I18n.t('invoices.reservation_other')
          end
        end

        data += [[details, number_to_currency(price)]]
        total_calc += price
        total_ht += item.net_amount
        total_vat += item.vat
      end

      ## subtract the coupon, if any
      unless invoice.coupon_id.nil?
        cp = invoice.coupon
        discount = 0
        if cp.type == 'percent_off'
          discount = total_calc * cp.percent_off / 100.00
        elsif cp.type == 'amount_off'
          # refunds of invoices with cash coupons: we need to ventilate coupons on paid items
          if invoice.is_a?(Avoir)
            paid_items = invoice.invoice.invoice_items.select { |ii| ii.amount.positive? }.length
            refund_items = invoice.invoice_items.select { |ii| ii.amount.positive? }.length

            discount = ((invoice.coupon.amount_off / paid_items) * refund_items) / 100.00
          else
            discount = cp.amount_off / 100.00
          end
        else
          raise InvalidCouponError
        end

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
      puts "ERROR: totals are NOT equals => expected: #{total}, computed: #{total_calc}" if total_calc != total

      # TVA
      vat_service = VatHistoryService.new
      vat_rate = vat_service.invoice_vat(invoice)
      if vat_rate != 0
        data += [[I18n.t('invoices.total_including_all_taxes'), number_to_currency(total)]]
        data += [[I18n.t('invoices.including_VAT_RATE', RATE: vat_rate), number_to_currency(total_vat / 100.00)]]
        data += [[I18n.t('invoices.including_total_excluding_taxes'), number_to_currency(total_ht / 100.00)]]
        data += [[I18n.t('invoices.including_amount_payed_on_ordering'), number_to_currency(total)]]

        # checking the round number
        rounded = sprintf('%.2f', total_vat / 100.00).to_f + sprintf('%.2f', total_ht / 100.00).to_f
        if rounded != sprintf('%.2f', total_calc).to_f
          puts 'ERROR: rounding the numbers cause an invoice inconsistency. ' \
               "Total expected: #{sprintf('%.2f', total_calc)}, total computed: #{rounded}"
        end
      else
        data += [[I18n.t('invoices.total_amount'), number_to_currency(total)]]
      end

      # display table
      table(data, header: true, column_widths: [400, 72], cell_style: { inline_format: true }) do
        row(0).font_style = :bold
        column(1).style align: :right

        if Setting.get('invoice_VAT-active')
          # Total incl. taxes
          row(-1).style align: :right
          row(-1).background_color = 'E4E4E4'
          row(-1).font_style = :bold
          # including VAT xx%
          row(-2).style align: :right
          row(-2).background_color = 'E4E4E4'
          row(-2).font_style = :italic
          # including total excl. taxes
          row(-3).style align: :right
          row(-3).background_color = 'E4E4E4'
          row(-3).font_style = :italic
          # including amount payed on ordering
          row(-4).style align: :right
          row(-4).background_color = 'E4E4E4'
          row(-4).font_style = :bold
        end
      end

      # optional description for refunds
      move_down 20
      text invoice.description if invoice.is_a?(Avoir) && invoice.description

      # payment details
      move_down 20
      if invoice.is_a?(Avoir)
        payment_verbose = I18n.t('invoices.refund_on_DATE', DATE:I18n.l(invoice.avoir_date.to_date)) + ' '
        case invoice.payment_method
        when 'stripe'
          payment_verbose += I18n.t('invoices.by_stripe_online_payment')
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
          puts "ERROR : specified refunding method (#{payment_verbose}) is unknown"
        end
        payment_verbose += ' ' + I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(total))
      else
        # subtract the wallet amount for this invoice from the total
        if invoice.wallet_amount
          wallet_amount = invoice.wallet_amount / 100.00
          total -= wallet_amount
        else
          wallet_amount = nil
        end

        # payment method
        payment_verbose = if invoice.paid_with_stripe?
                            I18n.t('invoices.settlement_by_debit_card')
                          else
                            I18n.t('invoices.settlement_done_at_the_reception')
                          end

        # if the invoice was 100% payed with the wallet ...
        payment_verbose = I18n.t('invoices.settlement_by_wallet') if total.zero? && wallet_amount

        payment_verbose += ' ' + I18n.t('invoices.on_DATE_at_TIME', DATE: I18n.l(invoice.created_at.to_date), TIME:I18n.l(invoice.created_at, format: :hour_minute))
        if total.positive? || !invoice.wallet_amount
          payment_verbose += ' ' + I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(total))
        end
        if invoice.wallet_amount
          payment_verbose += if total.positive?
                               ' ' + I18n.t('invoices.and') + ' ' + I18n.t('invoices.by_wallet') + ' ' +
                                 I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(wallet_amount))
                             else
                               ' ' + I18n.t('invoices.for_an_amount_of_AMOUNT', AMOUNT: number_to_currency(wallet_amount))
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
        image "#{Rails.root}/app/pdfs/data/watermark-#{I18n.locale}.png", at: [90, 150]
      end
    end
  end

  private

  def subscription_verbose(subscription, username)
    subscription_start_at = subscription.expired_at - subscription.plan.duration
    duration_verbose = I18n.t("duration.#{subscription.plan.interval}", count: subscription.plan.interval_count)
    I18n.t('invoices.subscription_of_NAME_for_DURATION_starting_from_DATE',
           NAME: username,
           DURATION: duration_verbose,
           DATE: I18n.l(subscription_start_at.to_date))
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

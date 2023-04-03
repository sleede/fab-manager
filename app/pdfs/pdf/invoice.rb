# frozen_string_literal: true

# Generate a downloadable PDF file for the recorded invoice
class Pdf::Invoice < Prawn::Document
  require 'stringio'
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  # @param invoice [Invoice]
  def initialize(invoice)
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
    font('Open-Sans', size: 10) do
      # general information
      text I18n.t(invoice.is_a?(Avoir) ? 'invoices.refund_invoice_reference' : 'invoices.invoice_reference',
                  **{ REF: invoice.reference }), leading: 3
      text I18n.t('invoices.code', **{ CODE: Setting.get('invoice_code-value') }), leading: 3 if Setting.get('invoice_code-active')
      if invoice.main_item&.object_type != WalletTransaction.name
        text I18n.t('invoices.order_number', **{ NUMBER: invoice.order_number }), leading: 3
      end
      if invoice.is_a?(Avoir)
        text I18n.t('invoices.refund_invoice_issued_on_DATE', **{ DATE: I18n.l(invoice.avoir_date.to_date) })
      else
        text I18n.t('invoices.invoice_issued_on_DATE', **{ DATE: I18n.l(invoice.created_at.to_date) })
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

        data += [[Invoices::ItemLabelService.build(invoice, item), number_to_currency(price)]]
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
          data += [[I18n.t('invoices.including_VAT_RATE',
                           **{ RATE: rate[:vat_rate],
                               AMOUNT: number_to_currency(rate[:amount] / 100.00),
                               NAME: Setting.get('invoice_VAT-name') }),
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
      text Invoices::PaymentDetailsService.build(invoice, total)

      # important information
      move_down 40
      txt = parse_html(Setting.get('invoice_text').to_s)
      txt.each_line do |line|
        text line, style: :bold, inline_format: true
      end

      # address and legals information
      move_down 40
      txt = parse_html(Setting.get('invoice_legals').to_s)
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

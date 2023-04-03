# frozen_string_literal: true

# Provides methods to help testing invoices
module InvoiceHelper
  # Force the invoice generation worker to run NOW and check the resulting file generated.
  # Delete the file afterwards.
  # @param invoice [Invoice]
  # @yield an optional block may be provided for additional specific assertions on the invoices PDF lines
  def assert_invoice_pdf(invoice)
    assert_not_nil invoice, 'Invoice was not created'

    generate_pdf(invoice)

    assert File.exist?(invoice.file), 'Invoice PDF was not generated'

    # now we check the file content
    reader = PDF::Reader.new(invoice.file)
    assert_equal 1, reader.page_count # single page invoice
    page = reader.pages.first
    lines = page.text.scan(/^.+/)

    check_amounts(invoice, lines)
    check_user(invoice, lines)

    yield lines if block_given?

    File.delete(invoice.file)
  end

  # @param customer [User]
  # @param operator [User]
  # @return [Invoice] saved
  def sample_reservation_invoice(customer, operator)
    machine = Machine.first
    slot = Availabilities::AvailabilitiesService.new(operator)
                                                .machines([machine], customer, { start: Time.current, end: 1.year.from_now })
                                                .find { |s| !s.full?(machine) }
    reservation = Reservation.new(
      reservable: machine,
      slots_reservations: [SlotsReservation.new({ slot_id: slot.id })],
      statistic_profile: customer.statistic_profile
    )
    reservation.save
    invoice = Invoice.new(
      total: 1000,
      invoicing_profile: customer.invoicing_profile,
      statistic_profile: customer.statistic_profile,
      operator_profile: operator.invoicing_profile,
      payment_method: '',
      invoice_items: [InvoiceItem.new(
        amount: 1000,
        description: "reservation #{machine.name}",
        object: reservation,
        main: true
      )]
    )
    unless operator.privileged?
      invoice.payment_method = 'card'
      invoice.payment_gateway_object = PaymentGatewayObject.new(
        gateway_object_id: 'pi_3LpALs2sOmf47Nz91QyFI7nP',
        gateway_object_type: 'Stripe::PaymentIntent'
      )
    end
    invoice.save!
    invoice
  end

  private

  def generate_pdf(invoice)
    invoice_worker = InvoiceWorker.new
    invoice_worker.perform(invoice.id)
  end

  # Parse a line of text read from a PDF file and return the price included inside
  # Line of text should be of form 'Label              $10.00'
  # @returns {float}
  def parse_amount_from_invoice_line(line)
    line[line.rindex(' ') + 1..].tr(I18n.t('number.currency.format.unit'), '').gsub(/[$,]/, '').to_f
  end

  # check VAT and total excluding taxes
  def check_amounts(invoice, lines)
    ht_amount = invoice.total
    lines.each do |line|
      # check that the numbers printed into the PDF file match the total stored in DB
      if line.include? I18n.t('invoices.total_amount')
        assert_equal invoice.total / 100.0, parse_amount_from_invoice_line(line), 'Invoice total rendered in the PDF file does not match'
      end

      # check that the VAT was correctly applied if it was configured
      ht_amount = parse_amount_from_invoice_line(line) if line.include? I18n.t('invoices.including_total_excluding_taxes')
    end

    vat_service = VatHistoryService.new
    invoice.invoice_items.each do |item|
      vat_rate = vat_service.invoice_item_vat(item)
      if vat_rate.positive?
        computed_ht = sprintf('%.2f', (item.amount_after_coupon / ((vat_rate / 100.00) + 1)) / 100.00).to_f

        assert_equal computed_ht, item.net_amount / 100.00, 'Total excluding taxes rendered in the PDF file is not computed correctly'
      else
        assert_equal item.amount_after_coupon, item.net_amount, 'VAT information was rendered in the PDF file despite that VAT was disabled'
      end
    end
  end

  # check the recipient & the address
  def check_user(invoice, lines)
    if invoice.invoicing_profile.organization
      assert lines.first.include?(invoice.invoicing_profile.organization.name), 'On the PDF invoice, organization name is invalid'
      assert invoice.invoicing_profile.organization.address.address.include?(lines[2].split('             ').last.strip),
             'On the PDF invoice, organization address is invalid'
    else
      assert lines.first.include?(invoice.invoicing_profile.full_name), 'On the PDF invoice, customer name is invalid'
      assert invoice.invoicing_profile.address.address.include?(lines[2].split('             ').last.strip),
             'On the PDF invoice, customer address is invalid'
    end
    # check the email
    assert lines[1].include?(invoice.invoicing_profile.email), 'On the PDF invoice, email is invalid'
  end
end

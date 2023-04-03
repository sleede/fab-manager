# frozen_string_literal: true

# Generates the PDF Document associated with the provided invoice, and send it to the customer
class InvoiceWorker
  include Sidekiq::Worker

  def perform(invoice_id)
    # generate a invoice
    invoice = Invoice.find invoice_id
    pdf = ::Pdf::Invoice.new(invoice).render

    # store invoice on drive
    File.binwrite(invoice.file, pdf)

    # notify user + send invoice by mail
    if invoice.is_a?(Avoir)
      NotificationCenter.call type: 'notify_user_when_avoir_ready',
                              receiver: invoice.user,
                              attached_object: invoice
    else
      NotificationCenter.call type: 'notify_user_when_invoice_ready',
                              receiver: invoice.user,
                              attached_object: invoice
    end
  end
end

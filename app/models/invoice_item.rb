class InvoiceItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :subscription

  has_one :invoice_item # to associated invoice_items of an invoice to invoice_items of an avoir

  after_create :chain_record

  def chain_record
    max_date = created_at || Time.current
    previous = InvoiceItem.where('created_at < ?', max_date)
                          .order('created_at DESC')
                          .limit(1)

    columns = InvoiceItem.columns.map(&:name)
                         .delete_if { |c| c == 'footprint' }

    sha256 = Digest::SHA256.new
    self.footprint = sha256.hexdigest "#{columns.map { |c| self[c] }.join}#{previous.first ? previous.first.footprint : ''}"
  end
end

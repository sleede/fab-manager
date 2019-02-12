class InvoiceItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :subscription

  has_one :invoice_item # to associated invoice_items of an invoice to invoice_items of an avoir

  after_create :chain_record

  def chain_record
    self.footprint = compute_footprint
  end

  def check_footprint
    footprint == compute_footprint
  end

  private

  def compute_footprint
    max_date = created_at || Time.current
    previous = InvoiceItem.where('created_at < ?', max_date)
                          .order('created_at DESC')
                          .limit(1)

    columns = InvoiceItem.columns.map(&:name)
                         .delete_if { |c| %w[footprint updated_at].include? c }

    sha256 = Digest::SHA256.new
    self.footprint = sha256.hexdigest "#{columns.map { |c| self[c] }.join}#{previous.first ? previous.first.footprint : ''}"
  end
end

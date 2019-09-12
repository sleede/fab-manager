# frozen_string_literal: true

require 'checksum'

# A single line inside an invoice. Can be a subscription or a reservation
class InvoiceItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :subscription

  has_one :invoice_item # to associated invoice_items of an invoice to invoice_items of an avoir

  after_create :chain_record
  after_update :log_changes

  def chain_record
    self.footprint = compute_footprint
    save!
  end

  def check_footprint
    footprint == compute_footprint
  end

  private

  def compute_footprint
    previous = InvoiceItem.where('id < ?', id)
                          .order('id DESC')
                          .limit(1)

    columns = InvoiceItem.columns.map(&:name)
                         .delete_if { |c| %w[footprint updated_at].include? c }

    Checksum.text("#{columns.map { |c| self[c] }.join}#{previous.first ? previous.first.footprint : ''}")
  end

  def log_changes
    return if Rails.env.test?
    return unless changed?

    puts "WARNING: InvoiceItem update triggered [ id: #{id}, invoice reference: #{invoice.reference} ]"
    puts '----------   changes   ----------'
    puts changes
    puts '---------------------------------'
  end
end

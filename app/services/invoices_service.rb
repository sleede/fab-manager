# frozen_string_literal: true

# Provides methods for accessing Invoices resources and properties
class InvoicesService
  # return a paginated list of invoices, ordered by the given criterion and optionally filtered
  # @param order_key {string} any column from invoices or joined a table
  # @param direction {string} 'ASC' or 'DESC', linked to order_key
  # @param page {number} page number, used to paginate results
  # @param size {number} number of items per page
  # @param filters {Hash} allowed filters: number, customer, date.
  def self.list(order_key, direction, page, size, filters = {})
    invoices = Invoice.includes(:avoir, :invoicing_profile, invoice_items: %i[subscription invoice_item])
                      .joins(:invoicing_profile)
                      .order("#{order_key} #{direction}")
                      .page(page)
                      .per(size)


    if filters[:number].size.positive?
      invoices = invoices.where(
        'invoices.reference LIKE :search',
        search: "#{filters[:number]}%"
      )
    end
    if filters[:customer].size.positive?
      # ILIKE => PostgreSQL case-insensitive LIKE
      invoices = invoices.where(
        'invoicing_profiles.first_name ILIKE :search OR invoicing_profiles.last_name ILIKE :search',
        search: "%#{filters[:customer]}%"
      )
    end
    unless filters[:date].nil?
      invoices = invoices.where(
        "date_trunc('day', invoices.created_at) = :search",
        search: "%#{DateTime.iso8601(filters[:date]).to_time.to_date}%"
      )
    end

    invoices
  end

  # Parse the order_by clause provided by JS client from '-column' form to SQL compatible form
  # @param order_by {string} expected form: 'column' or '-column'
  def self.parse_order(order_by)
    direction = (order_by[0] == '-' ? 'DESC' : 'ASC')
    key = (order_by[0] == '-' ? order_by[1, order_by.size] : order_by)

    order_key = case key
                when 'reference'
                  'invoices.reference'
                when 'date'
                  'invoices.created_at'
                when 'total'
                  'invoices.total'
                when 'name'
                  'profiles.first_name'
                else
                  'invoices.id'
                end
    { direction: direction, order_key: order_key }
  end
end

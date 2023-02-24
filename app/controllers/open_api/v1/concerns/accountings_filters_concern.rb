# frozen_string_literal: true

# Filter the list of accounting lines by the given parameters
module OpenAPI::V1::Concerns::AccountingsFiltersConcern
  extend ActiveSupport::Concern

  included do
    # @param lines [ActiveRecord::Relation<AccountingLine>]
    # @param filters [ActionController::Parameters]
    def filter_by_after(lines, filters)
      return lines if filters[:after].blank?

      lines.where('date >= ?', Time.zone.parse(filters[:after]))
    end

    # @param lines [ActiveRecord::Relation<AccountingLine>]
    # @param filters [ActionController::Parameters]
    def filter_by_before(lines, filters)
      return lines if filters[:before].blank?

      lines.where('date <= ?', Time.zone.parse(filters[:before]))
    end

    # @param lines [ActiveRecord::Relation<AccountingLine>]
    # @param filters [ActionController::Parameters]
    def filter_by_invoice(lines, filters)
      return lines if filters[:invoice_id].blank?

      lines.where(invoice_id: may_array(filters[:invoice_id]))
    end

    # @param lines [ActiveRecord::Relation<AccountingLine>]
    # @param filters [ActionController::Parameters]
    def filter_by_line_type(lines, filters)
      return lines if filters[:type].blank?

      lines.where(line_type: may_array(filters[:type]))
    end
  end
end

# frozen_string_literal: true

# module definition
module Invoices; end

# The recipient may be be an individual or an organization
class Invoices::RecipientService
  class << self
    # Get the full name of the recipient for the given invoice.
    def name(invoice)
      if invoice.invoicing_profile.organization
        name = invoice.invoicing_profile.organization.name
        "#{name} (#{invoice.invoicing_profile.full_name})"
      else
        invoice.invoicing_profile.full_name
      end
    end

    # Get the street address of the recipient for the given invoice.
    def address(invoice)
      invoice.invoicing_profile&.invoicing_address
    end

    # Get the optional data in profile_custom_fields, if the recipient is an organization
    def organization_data(invoice)
      return unless invoice.invoicing_profile.organization

      invoice.invoicing_profile.user_profile_custom_fields&.joins(:profile_custom_field)
              &.where('profile_custom_fields.actived' => true)
              &.order('profile_custom_fields.id ASC')
              &.select { |f| f.value.present? }
              &.map { |f| "#{f.profile_custom_field.label}: #{f.value}" }
    end
  end
end

# frozen_string_literal: true

require 'asaas'
require 'payment/helper'

# Provides various methods around the Asaas payment gateway
class Asaas::Helper < Payment::Helper
  class << self
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'asaas'

      %w[asaas_api_key asaas_environment].all? { |setting| Setting.get(setting).present? }
    end

    def human_error(error)
      I18n.t('errors.messages.gateway_error', MESSAGE: error.message)
    end

    def payment_method
      'transfer'
    end

    def due_date
      Time.zone.today.to_s
    end

    def customer_attributes(user)
      {
        name: user.invoicing_profile.full_name,
        email: user.invoicing_profile.email,
        mobilePhone: user.profile&.phone,
        externalReference: "fab-manager-user-#{user.id}",
        notificationDisabled: true
      }.compact
    end

    def payment_description(source)
      case source
      when Order
        "Fab-manager order #{source.reference || source.token}"
      else
        'Fab-manager Pix payment'
      end
    end
  end
end

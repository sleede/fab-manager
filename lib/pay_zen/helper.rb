# frozen_string_literal: true

# PayZen payement gateway
module PayZen; end

## Provides various methods around the PayZen payment gateway
class PayZen::Helper
  class << self
    ## Is the PayZen gateway enabled?
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'payzen'

      res = true
      %w[payzen_username payzen_password payzen_endpoint payzen_public_key payzen_hmac payzen_currency].each do |pz_setting|
        res = false unless Setting.get(pz_setting).present?
      end
      res
    end

    ## generate an unique string reference for the content of a cart
    def generate_ref(cart_items, customer)
      require 'sha3'

      content = { cart_items: cart_items, customer: customer }.to_json + DateTime.current.to_s
      SHA3::Digest.hexdigest(:sha256, content)[0...12]
    end

    ## Generate a hash map compatible with PayZen 'V4/Customer/Customer'
    def generate_customer(customer_id)
      customer = User.find(customer_id)
      address = if customer.organization?
                  customer.invoicing_profile.organization.address&.address
                else
                  customer.invoicing_profile.address&.address
                end

      {
        reference: customer.id,
        email: customer.invoicing_profile.email,
        billingDetails: {
          firstName: customer.invoicing_profile.first_name,
          lastName: customer.invoicing_profile.last_name,
          legalName: customer.organization? ? customer.invoicing_profile.organization.name : nil,
          address: address
        },
        shippingDetails: {
          category: customer.organization? ? 'COMPANY' : 'PRIVATE',
          shippingMethod: 'ETICKET'
        }
      }
    end
  end
end

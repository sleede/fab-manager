# frozen_string_literal: true

# PayZen payement gateway
module PayZen; end

## Provides various methods around the PayZen payment gateway
class PayZen::Helper
  class << self
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'payzen'

      res = true
      %w[payzen_username payzen_password payzen_endpoint payzen_public_key payzen_hmac payzen_currency].each do |pz_setting|
        res = false unless Setting.get(pz_setting).present?
      end
      res
    end

    def generate_ref(cart_items, customer)
      require 'sha3'

      content = { cart_items: cart_items, customer: customer }.to_json + DateTime.current.to_s
      SHA3::Digest.hexdigest(:sha256, content)
    end
  end
end

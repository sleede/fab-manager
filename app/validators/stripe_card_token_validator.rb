# frozen_string_literal: true

# validates the given card token through the Stripe API
class StripeCardTokenValidator
  def validate(record)
    return unless options[:token]

    res = Stripe::Token.retrieve(options[:token], api_key: Setting.get('stripe_secret_key'))
    if res[:id] != options[:token]
      record.errors[:card_token] << "A problem occurred while retrieving the card with the specified token: #{res.id}"
    end
  rescue Stripe::InvalidRequestError => e
    record.errors[:card_token] << e
  end
end

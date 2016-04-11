
class StripeCardTokenValidator
  def validate(record)
    if options[:token]
      begin
        res = Stripe::Token.retrieve(options[:token])
        if res[:id] != options[:token]
          record.errors[:card_token] << "A problem occurred while retrieving the card with the specified token: #{res.id}"
        end
      rescue Stripe::InvalidRequestError => e
        record.errors[:card_token] << e
      end
    end
  end
end
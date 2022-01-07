# frozen_string_literal: true

# Raised when an an error occurred with the PayZen payment gateway
class PayzenError < PaymentGatewayError
  def details
    JSON.parse(message.gsub('=>', ':').gsub('nil', 'null'))
  end
end


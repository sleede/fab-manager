# frozen_string_literal: true

require 'payment/item'
require 'pay_zen/order'
require 'pay_zen/subscription'
require 'pay_zen/token'
require 'pay_zen/transaction'

# PayZen payement gateway
module PayZen; end

## generic wrapper around PayZen classes
class PayZen::Item < Payment::Item
  attr_accessor :id

  def retrieve(id = nil, *args)
    @id ||= id
    @args ||= args
    params = [@id].concat(@args)
    params.compact!

    client = klass.constantize.new
    client.get(*params)
  end

  def payment_mean?
    klass == 'PayZen::Token'
  end
end

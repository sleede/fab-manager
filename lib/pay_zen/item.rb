# frozen_string_literal: true

require 'payment/item'

# PayZen payement gateway
module PayZen; end

## generic wrapper around PayZen classes
class PayZen::Item < Payment::Item
  attr_accessor :id

  def retrieve(id)
    @id ||= id
    client = klass.constantize
    client.get(@id)
  end
end
